import pytest
from fastapi.testclient import TestClient
from datetime import datetime, timezone
import uuid
import os
from dotenv import load_dotenv
import httpx
import asyncio
import json

# Load environment variables from .env file
load_dotenv()

# Get environment variables with defaults
API_HOST = os.getenv("API_HOST", "localhost")
API_PORT = os.getenv("API_PORT", "8000")
API_URL = f"http://{API_HOST}:{API_PORT}"

# Test client fixture that connects to the Docker container
@pytest.fixture
def client():
    with httpx.Client(base_url=API_URL) as client:
        yield client

# Mock data fixtures
@pytest.fixture
def mock_public_user():
    return "public"

@pytest.fixture
def mock_directories():
    return {
        "documents": {
            "id": str(uuid.uuid4()),
            "name": "Documents",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc),
            "parent_id": None,
            "child_counts": {"directories": 3, "files": 0, "total": 3}
        },
        "work": {
            "id": str(uuid.uuid4()),
            "name": "Work",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc),
            "parent_id": "documents_id",  # Will be replaced with actual ID
            "child_counts": {"directories": 0, "files": 3, "total": 3}
        }
    }

@pytest.fixture
def mock_files():
    return {
        "report": {
            "id": str(uuid.uuid4()),
            "name": "report_2024.pdf",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc),
            "parent_id": "work_id",  # Will be replaced with actual ID
            "storage_id": str(uuid.uuid4()),
            "metadata": {"type": "pdf", "size": "1MB", "status": "final"},
            "tags": {"names": ["work", "final"], "ids": [1, 2]}
        },
        "presentation": {
            "id": str(uuid.uuid4()),
            "name": "presentation.pptx",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc),
            "parent_id": "work_id",  # Will be replaced with actual ID
            "storage_id": str(uuid.uuid4()),
            "metadata": {"type": "powerpoint", "size": "5MB", "status": "final"},
            "tags": {"names": ["final"], "ids": [2]}
        }
    }

# Mock database query results
async def mock_execute_query(query: str, params: tuple):
    # This will be implemented in each test as needed
    pass

# Patch the execute_query function
@pytest.fixture
def mock_db(monkeypatch):
    monkeypatch.setattr("vfs_api.routes.execute_query", mock_execute_query)

# Basic test to check if the API is running
def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

# Test listing directories
def test_list_directories(client, mock_public_user):
    response = client.get("/directories", params={"user_token": mock_public_user})
    assert response.status_code == 200
    data = response.json()
    assert "directories" in data
    assert "files" in data

# Test creating a directory
def test_create_directory(client, mock_public_user):
    # Create a unique directory name to avoid conflicts
    dir_name = f"TestDirectory_{uuid.uuid4().hex[:8]}"
    test_dir = {
        "name": dir_name,
        "parent_id": None
    }
    response = client.post("/directories", params={"user_token": mock_public_user}, json=test_dir)
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == dir_name

    # Cleanup - delete the created directory
    dir_id = data["id"]
    delete_response = client.request(
        "DELETE",
        f"/directories/{dir_id}",
        params={"user_token": mock_public_user},
        json={"recursive": True}
    )
    assert delete_response.status_code == 200

# Test creating and deleting a file
def test_create_and_delete_file(client, mock_public_user):
    # First create a directory with unique name to hold the file
    dir_name = f"TestFileDir_{uuid.uuid4().hex[:8]}"
    dir_response = client.post(
        "/directories",
        params={"user_token": mock_public_user},
        json={"name": dir_name, "parent_id": None}
    )
    assert dir_response.status_code == 200
    dir_data = dir_response.json()

    # Create a file in the directory
    file_data = {
        "filename": f"test_{uuid.uuid4().hex[:8]}.txt",
        "parent_id": dir_data["id"]
    }
    file_response = client.post("/files/", params={"user_token": mock_public_user}, json=file_data)
    assert file_response.status_code == 200
    created_file = file_response.json()

    # Delete the file
    delete_response = client.delete(
        f"/files/{created_file['id']}",
        params={"user_token": mock_public_user}
    )
    assert delete_response.status_code == 200

    # Cleanup - delete the directory
    client.request(
        "DELETE",
        f"/directories/{dir_data['id']}",
        params={"user_token": mock_public_user},
        json={"recursive": True}
    )

# Test searching for items
def test_search_items(client, mock_public_user):
    search_request = {
        "query": "test",
        "type": "all",
        "parent_id": None,
        "tags": [],
        "metadata": {}
    }
    response = client.post("/search", params={"user_token": mock_public_user}, json=search_request)
    assert response.status_code == 200
    data = response.json()
    assert "directories" in data
    assert "files" in data

# Test getting directory tree
def test_get_directory_tree(client, mock_public_user):
    response = client.get("/directories/tree", params={"user_token": mock_public_user})
    assert response.status_code == 200
    data = response.json()
    assert "items" in data

# Test getting directory details
def test_get_directory_details(client, mock_public_user):
    # First create a directory
    dir_name = f"TestDir_{uuid.uuid4().hex[:8]}"
    create_response = client.post(
        "/directories",
        params={"user_token": mock_public_user},
        json={"name": dir_name, "parent_id": None}
    )
    assert create_response.status_code == 200
    dir_id = create_response.json()["id"]

    # Get directory details
    response = client.get(f"/directories/{dir_id}", params={"user_token": mock_public_user})
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == dir_name

    # Cleanup
    client.request(
        "DELETE",
        f"/directories/{dir_id}",
        params={"user_token": mock_public_user},
        json={"recursive": True}
    )

# Test updating directory
def test_update_directory(client, mock_public_user):
    # Create initial directory
    dir_name = f"TestDir_{uuid.uuid4().hex[:8]}"
    create_response = client.post(
        "/directories",
        params={"user_token": mock_public_user},
        json={"name": dir_name, "parent_id": None}
    )
    dir_id = create_response.json()["id"]

    # Update directory name
    new_name = f"UpdatedDir_{uuid.uuid4().hex[:8]}"
    update_response = client.patch(
        f"/directories/{dir_id}",
        params={"user_token": mock_public_user},
        json={"updates": {"name": new_name}}
    )
    assert update_response.status_code == 200
    assert update_response.json()["name"] == new_name

    # Cleanup
    client.request(
        "DELETE",
        f"/directories/{dir_id}",
        params={"user_token": mock_public_user},
        json={"recursive": True}
    )

# Test copying directory
def test_copy_directory(client, mock_public_user):
    # Create source directory
    source_name = f"SourceDir_{uuid.uuid4().hex[:8]}"
    source_response = client.post(
        "/directories",
        params={"user_token": mock_public_user},
        json={"name": source_name, "parent_id": None}
    )
    source_id = source_response.json()["id"]

    # Create destination directory
    dest_name = f"DestDir_{uuid.uuid4().hex[:8]}"
    dest_response = client.post(
        "/directories",
        params={"user_token": mock_public_user},
        json={"name": dest_name, "parent_id": None}
    )
    dest_id = dest_response.json()["id"]

    # Copy directory
    copy_response = client.post(
        f"/directories/{source_id}/copy",
        params={"user_token": mock_public_user},
        json={"destination_parent_id": dest_id}
    )
    assert copy_response.status_code == 200

    # Cleanup
    for dir_id in [source_id, dest_id]:
        client.request(
            "DELETE",
            f"/directories/{dir_id}",
            params={"user_token": mock_public_user},
            json={"recursive": True}
        )

# Test file tags operations
def test_file_tags(client, mock_public_user):
    # Create a directory and file first
    dir_response = client.post(
        "/directories",
        params={"user_token": mock_public_user},
        json={"name": f"TestDir_{uuid.uuid4().hex[:8]}", "parent_id": None}
    )
    dir_id = dir_response.json()["id"]

    file_response = client.post(
        "/files/",
        params={"user_token": mock_public_user},
        json={"filename": "test.txt", "parent_id": dir_id}
    )
    file_id = file_response.json()["id"]

    # Add tags
    add_tags_response = client.post(
        f"/files/{file_id}/tags",
        params={"user_token": mock_public_user},
        json={"tags": ["test", "important"]}
    )
    assert add_tags_response.status_code == 200
    assert "test" in add_tags_response.json()["names"]

    # Update tags
    update_tags_response = client.patch(
        f"/files/{file_id}/tags",
        params={"user_token": mock_public_user},
        json={"tags": ["updated"]}
    )
    assert update_tags_response.status_code == 200
    assert "updated" in update_tags_response.json()["names"]

    # Remove tags
    remove_tags_response = client.request(
        "DELETE",
        f"/files/{file_id}/tags",
        params={"user_token": mock_public_user},
        json={"tags": ["updated"]}
    )

    assert remove_tags_response.status_code == 200
    assert len(remove_tags_response.json()["names"]) == 0

    # Cleanup
    client.delete(f"/files/{file_id}", params={"user_token": mock_public_user})
    client.request(
        "DELETE",
        f"/directories/{dir_id}",
        params={"user_token": mock_public_user},
        json={"recursive": True}
    )

# Test listing all tags
def test_list_tags(client, mock_public_user):
    response = client.get("/tags", params={"user_token": mock_public_user})
    assert response.status_code == 200
    data = response.json()
    assert "names" in data
    assert "ids" in data