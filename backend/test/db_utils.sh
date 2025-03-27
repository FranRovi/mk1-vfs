#!/bin/bash

# utilities for database interaction

# run a query on the database
run_query() {
    local query="$1"
    docker compose exec db psql -U $DB_USER -d $DB_NAME -t -c "$query" 2>&1 | xargs
}

# run a query on the database from a file
run_query_f() {
    local query="$1"
    docker compose exec db psql -U $DB_USER -d $DB_NAME -t -c "$(cat $query)" 2>&1 | xargs
}

# clear the database
clear_db() {
    run_query "DELETE FROM files;"
    run_query "DELETE FROM directories;"
    run_query "DELETE FROM tags;"
}

# Export the function so it can be used by other scripts
export run_query
export run_query_f
export clear_db