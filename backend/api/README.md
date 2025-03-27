# VFS API

Virtual File System API for managing directories and files.

## Features

- Directory management (create, delete, move, copy)
- File management (upload, download, delete, move, copy)
- File tagging system
- Search functionality
- Metadata support

## Configuration

The API can be configured using environment variables:

- `DB_HOST`: PostgreSQL host (default: localhost)
- `DB_PORT`: PostgreSQL port (default: 5432)
- `DB_NAME`: Database name (default: prism_vfs)
- `DB_USER`: Database user (default: prism_user)
- `DB_PASSWORD`: Database password (default: prism_password)


## Deployment

```bash
pip install .
python, -m vfs_api --verbose --host 0.0.0.0 --port 8000
```

## API Documentation

Once the server is running, you can access the API documentation at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## API Endpoints

### Directories
- `GET /directories` - List directories and files in parent directory
  - Query: `parent_id` (optional), `user_token`
  - Returns: List of directories and files with basic details

- `GET /directories/tree` - Get directory tree structure (DEPRECATED)
  - Query: `parent_id` (optional), `level`, `user_token`
  - Returns: Hierarchical tree of directories and files

- `GET /directories/{dir_id}` - Get directory details
  - Returns: Full directory information including child counts

- `POST /directories` - Create new directory
  - Body: `name`, `parent_id` (optional)
  - Returns: Created directory details

- `PATCH /directories/{dir_id}` - Update directory
  - Body: `name` and/or `parent_id` updates
  - Returns: Updated directory details

- `POST /directories/{dir_id}/copy` - Copy directory
  - Body: `destination_parent_id`
  - Returns: New directory details

- `DELETE /directories/{dir_id}` - Delete directory
  - Body: `recursive` (boolean)

### Files
- `GET /files/{file_id}` - Get file details
  - Returns: Full file information including metadata and tags

- `POST /files` - Create new file
  - Body: `filename`, `parent_id` (optional)
  - Returns: Created file details

- `PATCH /files/{file_id}` - Update file
  - Body: `name`, `parent_id`, `tags`, `metadata` updates
  - Returns: Updated file details

- `DELETE /files/{file_id}` - Delete file

- `POST /files/{file_id}/copy` - Copy file
  - Body: `destination_parent_id`
  - Returns: New file details

### Tags
- `GET /tags` - List all available tags
  - Returns: List of tag names and IDs

- `POST /files/{file_id}/tags` - Add tags to file
  - Body: List of tag names
  - Returns: Updated file tags

- `DELETE /files/{file_id}/tags` - Remove tags from file
  - Body: List of tag names to remove
  - Returns: Remaining file tags

- `PATCH /files/{file_id}/tags` - Replace all file tags
  - Body: New list of tag names
  - Returns: Updated file tags

### Search
- `POST /search` - Search files and directories
  - Body: `query`, `type`, `parent_id`, `tags`, `metadata`
  - Returns: Matching files and directories

## License

MK1 License for internal use only.