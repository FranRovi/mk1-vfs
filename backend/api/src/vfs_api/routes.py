from fastapi import APIRouter, HTTPException, Query
from typing import Optional
import uuid
import json
from vfs_api.db_utils import execute_query, DatabaseError, DatabaseNotFoundError
import vfs_api.schemas as schemas

router = APIRouter()

########################
#  Directory Routes
########################

# GET /directories - List directories and files in the specified parent directory.
@router.get("/directories", response_model=schemas.DirectoryListResponse)
async def list_directories(
    parent_id: Optional[str] = Query(default=None, description="Parent directory ID"),
    user_token: str = Query(default='public', description="User token for authentication")
):
    """List directories and files in the specified parent directory."""
    try:
        result = await execute_query(
            "SELECT * FROM directory_list(%s, %s)",
            (parent_id, user_token)
        )
        return result[0] if result else {"directories": [], "files": []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# GET /directories/tree - Get the directory tree structure.
@router.get("/directories/tree", response_model=schemas.DirectoryTreeResponse)
async def get_directory_tree(
    parent_id: Optional[str] = Query(default=None, description="Parent directory ID"),
    level: int = 100,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Get the directory tree structure."""
    try:
        result = await execute_query(
            "SELECT * FROM directory_tree(%s, %s, %s)",
            (parent_id, user_token, level)
        )
        return {"items": result[0] if result else []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# GET /directories/{dir_id} - Get directory details.
@router.get("/directories/{dir_id}", response_model=schemas.DirectoryDetails)
async def get_directory(
    dir_id: str,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Get directory details."""
    try:
        result = await execute_query(
            "SELECT * FROM directory_details(%s, %s)",
            (dir_id, user_token)
        )
        if not result or not result[0]:
            raise HTTPException(status_code=404, detail="Directory not found")
        return result[0]['directory_details']
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# POST /directories - Create a new directory.
@router.post("/directories", response_model=schemas.DirectoryDetails)
async def create_directory(
    request: schemas.DirectoryCreateRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Create a new directory."""
    try:
        result = await execute_query(
            "SELECT * FROM directory_create(%s, %s, %s)",
            (request.name, request.parent_id, user_token)
        )
        return result[0]['directory_details']
    except DatabaseError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


# PATCH /directories/{dir_id} - Update directory properties.
@router.patch("/directories/{dir_id}", response_model=schemas.DirectoryDetails)
async def update_directory(
    dir_id: str,
    request: schemas.DirectoryUpdateRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Update directory properties."""
    try:
        result = await execute_query(
            "SELECT * FROM directory_update(%s, %s, %s, %s)",
            (dir_id, request.updates.name, request.updates.parent_id, user_token)
        )
        if not result or not result[0]:
            raise DatabaseNotFoundError("Directory not found")
        return result[0]['directory_details']
    except DatabaseError as e:
        raise HTTPException(status_code=e.status_code, detail=e.message)


# POST /directories/{dir_id}/copy - Copy a directory to a new location.
@router.post("/directories/{dir_id}/copy", response_model=schemas.DirectoryDetails)
async def copy_directory(
    dir_id: str,
    request: schemas.DirectoryCopyRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Copy a directory to a new location."""
    try:
        result = await execute_query(
            "SELECT * FROM directory_copy(%s, %s, %s)",
            (dir_id, request.destination_parent_id, user_token)
        )
        return result[0]['directory_details']
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# DELETE /directories/{dir_id} - Delete a directory.
@router.delete("/directories/{dir_id}")
async def delete_directory(
    dir_id: str,
    request: schemas.DirectoryDeleteRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Delete a directory."""
    try:
        await execute_query(
            "SELECT directory_delete(%s, %s, %s)",
            (dir_id, request.recursive, user_token)
        )
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


########################
#  File Routes
########################

# GET /files/{file_id} - Get file details.
@router.get("/files/{file_id}", response_model=schemas.FileDetails)
async def get_file(
    file_id: str,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Get file details."""
    try:
        result = await execute_query(
            "SELECT * FROM file_details(%s, %s)",
            (file_id, user_token)
        )
        if not result or not result[0]:
            raise HTTPException(status_code=404, detail="File not found")
        return result[0]['file_details']
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# POST /files/ - Create a new file.
@router.post("/files/", response_model=schemas.FileDetails)
async def create_file(
    request: schemas.FileCreateRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Create a new file."""
    storage_id = str(uuid.uuid4())

    try:
        # Create file entry with uploading status
        result = await execute_query(
            "SELECT * FROM file_create(%s, %s, %s, %s, %s::jsonb)",
            (request.filename, request.parent_id, user_token, storage_id, json.dumps({}))
        )

        file_details = result[0]['file_details'] if result and result[0] else None

        return file_details

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# PATCH /files/{file_id} - Update file properties.
@router.patch("/files/{file_id}", response_model=schemas.FileDetails)
async def update_file(
    file_id: str,
    request: schemas.FileUpdateRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Update file properties."""
    try:
        # First update file properties
        result = await execute_query(
            "SELECT * FROM file_update(%s, %s, %s, %s::jsonb, %s)",
            (file_id, request.updates.name, request.updates.parent_id, json.dumps(request.updates.metadata), user_token)
        )

        # If tags are provided, update them
        if request.updates.tags is not None:
            await execute_query(
                "SELECT * FROM file_tags_set(%s, %s, %s)",
                (file_id, request.updates.tags, user_token)
            )

        # Get updated file details
        result = await execute_query(
            "SELECT * FROM file_details(%s, %s)",
            (file_id, user_token)
        )

        if not result or not result[0]:
            raise HTTPException(status_code=404, detail="File not found")
        return result[0]['file_details']
    except HTTPException:
        raise
    except Exception as e:
        if "name conflict" in str(e).lower():
            raise HTTPException(status_code=409, detail="File name already exists")
        raise HTTPException(status_code=500, detail=str(e))


# DELETE /files/{file_id} - Delete a file.
@router.delete("/files/{file_id}")
async def delete_file(
    file_id: str,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Delete a file."""
    try:
        # Finally delete the file from VFS
        await execute_query(
            "SELECT file_delete(%s, %s)",
            (file_id, user_token)
        )
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# POST /files/{file_id}/copy - Copy a file to a new location.
@router.post("/files/{file_id}/copy", response_model=schemas.FileDetails)
async def copy_file(
    file_id: str,
    request: schemas.FileCopyRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Copy a file to a new location."""
    try:
        result = await execute_query(
            "SELECT * FROM file_copy(%s, %s, %s)",
            (file_id, request.destination_parent_id, user_token)
        )
        return result[0]['file_details']
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


########################
#  File Tag Routes
########################

# POST /files/{file_id}/tags - Add tags to a file.
@router.post("/files/{file_id}/tags", response_model=schemas.FileTags)
async def add_tags(
    file_id: str,
    request: schemas.FileAddTagsRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Add tags to a file."""
    try:
        result = await execute_query(
            "SELECT * FROM file_tags_add(%s, %s, %s)",
            (file_id, request.tags, user_token)
        )
        return result[0]['tags'] if result else {}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# DELETE /files/{file_id}/tags - Remove tags from a file.
@router.delete("/files/{file_id}/tags", response_model=schemas.FileTags)
async def remove_tags(
    file_id: str,
    request: schemas.FileRemoveTagsRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Remove tags from a file."""
    try:
        result = await execute_query(
            "SELECT * FROM file_tags_remove(%s, %s, %s)",
            (file_id, request.tags, user_token)
        )
        return result[0]['tags'] if result else {}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# PATCH /files/{file_id}/tags - Replace all tags of a file.
@router.patch("/files/{file_id}/tags", response_model=schemas.FileTags)
async def update_tags(
    file_id: str,
    request: schemas.FileUpdateTagsRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Replace all tags of a file."""
    try:
        result = await execute_query(
            "SELECT * FROM file_tags_set(%s, %s, %s)",
            (file_id, request.tags, user_token)
        )
        return result[0]['tags'] if result else {}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


########################
#  Tag Routes
########################

# GET /tags - List all tags for the user.
@router.get("/tags", response_model=schemas.FileTags)
async def list_tags(
    user_token: str = Query(default='public', description="User token for authentication")
):
    """List all tags for the user."""
    try:
        result = await execute_query(
            "SELECT * FROM tags_list(%s)",
            (user_token,)
        )
        # Transform the result into FileTags format
        if result:
            names = [row['name'] for row in result]
            ids = [row['id'] for row in result]
            return schemas.FileTags(names=names, ids=ids)
        return schemas.FileTags(names=[], ids=[])
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


########################
#  Search Routes
########################

# POST /search - Search for files and directories.
@router.post("/search", response_model=schemas.ItemSearchResponse)
async def search_items(
    request: schemas.SearchRequest,
    user_token: str = Query(default='public', description="User token for authentication")
):
    """Search for files and directories."""
    try:
        result = await execute_query(
            "SELECT * FROM item_search(%s, %s, %s, %s, %s::jsonb, %s)",
            (
                request.query,
                request.type,
                request.parent_id,
                request.tags,
                json.dumps(request.metadata),
                user_token
            )
        )
        return result[0] if result else {"directories": [], "files": []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

