# Database utilities module for PostgreSQL connection management and operations.
# Provides connection pooling and core database operations.

import os
import time
from typing import Any, Dict, List, Optional, Tuple
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager
from fastapi import HTTPException

class DatabaseError(Exception):
    """Base class for database-related errors."""
    def __init__(self, message: str, status_code: int = 500):
        self.message = message
        self.status_code = status_code
        super().__init__(message)

class DatabaseNotFoundError(DatabaseError):
    """Raised when a requested resource is not found."""
    def __init__(self, message: str):
        super().__init__(message, status_code=404)

class DatabaseConflictError(DatabaseError):
    """Raised when there's a conflict (e.g., duplicate name)."""
    def __init__(self, message: str):
        super().__init__(message, status_code=409)

class DatabasePermissionError(DatabaseError):
    """Raised when there's a permission issue."""
    def __init__(self, message: str):
        super().__init__(message, status_code=403)

def handle_database_error(e: Exception) -> None:
    """Convert database errors to appropriate DatabaseError types."""
    error_msg = str(e).lower()

    if "already exists" in error_msg or "name conflict" in error_msg:
        raise DatabaseConflictError("Resource name already exists")
    elif "not found" in error_msg or "access denied" in error_msg:
        raise DatabaseNotFoundError(str(e))
    elif "permission denied" in error_msg:
        raise DatabasePermissionError(str(e))
    else:
        raise DatabaseError(str(e))

# Configuration from environment variables
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'prism_vfs'),
    'user': os.getenv('DB_USER', 'prism_user'),
    'password': os.getenv('DB_PASSWORD', 'prism_password'),
}

# Connection pool configuration
MIN_CONNECTIONS = 1
MAX_CONNECTIONS = 10
MAX_RETRIES = 3
RETRY_DELAY = 1  # seconds

PUBLIC_USER_TOKEN = 'public'

# Initialize connection pool
try:
    connection_pool = pool.SimpleConnectionPool(
        MIN_CONNECTIONS,
        MAX_CONNECTIONS,
        **DB_CONFIG,
        cursor_factory=RealDictCursor
    )
except psycopg2.Error as e:
    raise Exception(f"Failed to initialize connection pool: {e}")

@contextmanager
def get_connection():
    """Get a database connection from the pool."""
    connection = None
    retry_count = 0

    while retry_count < MAX_RETRIES:
        try:
            connection = connection_pool.getconn()
            yield connection
            break
        except psycopg2.Error as e:
            retry_count += 1
            if retry_count == MAX_RETRIES:
                raise Exception(f"Failed to get database connection after {MAX_RETRIES} attempts: {e}")
            time.sleep(RETRY_DELAY)
        finally:
            if connection:
                connection_pool.putconn(connection)

@contextmanager
def get_cursor():
    """Get a database cursor using a connection from the pool."""
    with get_connection() as connection:
        cursor = connection.cursor()
        try:
            yield cursor
            connection.commit()
        except Exception:
            connection.rollback()
            raise
        finally:
            cursor.close()

async def execute_query(query: str, params: Optional[tuple] = None) -> List[Dict[str, Any]]:
    """Execute a single query and return the results."""
    with get_cursor() as cursor:
        try:
            cursor.execute(query, params)
            if cursor.description:
                return cursor.fetchall()
            return []
        except psycopg2.Error as e:
            handle_database_error(e)

async def execute_transaction(queries_and_params: List[Tuple[str, Optional[tuple]]]) -> List[List[Dict[str, Any]]]:
    """Execute multiple queries in a single transaction."""
    results = []
    with get_connection() as connection:
        with connection.cursor() as cursor:
            try:
                for query, params in queries_and_params:
                    cursor.execute(query, params)
                    if cursor.description:
                        results.append(cursor.fetchall())
                    else:
                        results.append([])
                connection.commit()
            except psycopg2.Error as e:
                connection.rollback()
                handle_database_error(e)
            except Exception as e:
                connection.rollback()
                raise DatabaseError(str(e))
    return results

def close_pool():
    """Close the connection pool."""
    if connection_pool:
        connection_pool.closeall()