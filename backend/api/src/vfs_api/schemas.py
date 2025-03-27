from typing import Optional, List, Dict, Any, Literal
from pydantic import BaseModel
from datetime import datetime

class DirectoryChildCounts(BaseModel):
    directories: int
    files: int
    total: int

class DirectoryDetails(BaseModel):
    id: str  # UUID
    name: str
    created_at: datetime
    updated_at: datetime
    parent_id: Optional[str] = None  # UUID, optional for root directory
    child_counts: DirectoryChildCounts

class FileTags(BaseModel):
    names: Optional[List[str|None]] = []
    ids: Optional[List[int|None]] = []

class FileDetails(BaseModel):
    id: str  # UUID
    name: str
    created_at: datetime
    updated_at: datetime
    parent_id: Optional[str] = None  # UUID, optional for root directory
    storage_id: str
    metadata: Optional[Dict[str, Any]] = {}  # Default empty dict if no metadata
    tags: FileTags

class ShortDetails(BaseModel):
    id: str  # UUID
    name: str
    created_at: datetime


class SearchRequest(BaseModel):
    query: Optional[str] = None
    type: Optional[Literal['all', 'file', 'directory']] = "all"
    parent_id: Optional[str] = None
    tags: Optional[List[str]] = None
    metadata: Optional[Dict[str, Any]] = None

class TreeItem(BaseModel):
    id: str  # UUID
    name: str
    created_at: datetime
    type: Literal['file', 'directory']
    children: Optional[List['TreeItem']] = None

# This is needed for the recursive type reference in TreeItem
TreeItem.model_rebuild()


########################
#  Directory Routes
########################

# GET /directories - List directories and files in the specified parent directory.

class DirectoryListResponse(BaseModel):
    directories: List[ShortDetails]
    files: List[ShortDetails]

# GET /directories/tree - Get the directory tree structure.

class DirectoryTreeResponse(BaseModel):
    items: Dict[Literal['tree'], List[TreeItem]]

# GET /directories/{dir_id} - Get directory details.

# POST /directories - Create a new directory.
class DirectoryCreateRequest(BaseModel):
    name: str
    parent_id: Optional[str] = None

# PATCH /directories/{dir_id} - Update directory properties.
class DirectoryUpdate(BaseModel):
    name: Optional[str] = None
    parent_id: Optional[str] = None

class DirectoryUpdateRequest(BaseModel):
    updates: DirectoryUpdate


# POST /directories/{dir_id}/copy - Copy a directory to a new location.
class DirectoryCopyRequest(BaseModel):
    destination_parent_id: Optional[str] = None


# DELETE /directories/{dir_id} - Delete a directory.
class DirectoryDeleteRequest(BaseModel):
    recursive: bool = False


########################
#  File Routes
########################

# GET /files/{file_id} - Get file details.

# POST /files/ - Initialize a new file upload.
class FileCreateRequest(BaseModel):
    filename: str
    parent_id: Optional[str] = None


# PATCH /files/{file_id} - Update file properties.
class FileUpdate(BaseModel):
    name: Optional[str] = None
    parent_id: Optional[str] = None
    tags: Optional[List[str]] = None
    metadata: Optional[Dict[str, Any]] = None

class FileUpdateRequest(BaseModel):
    updates: FileUpdate


# DELETE /files/{file_id} - Delete a file.


# POST /files/{file_id}/copy - Copy a file to a new location.
class FileCopyRequest(BaseModel):
    destination_parent_id: Optional[str] = None


########################
#  File Tag Routes
########################

# POST /files/{file_id}/tags - Add tags to a file.
class FileAddTagsRequest(BaseModel):
    tags: List[str]


# DELETE /files/{file_id}/tags - Remove tags from a file.
class FileRemoveTagsRequest(BaseModel):
    tags: List[str]


# PATCH /files/{file_id}/tags - Replace all tags of a file.
class FileUpdateTagsRequest(BaseModel):
    tags: List[str]


########################
#  Tag Routes
########################

# GET /tags - List all tags for the user.

########################
#  Search Routes
########################

# POST /search - Search for files and directories.

class ItemSearchResultFile(BaseModel):
    id: str  # UUID
    name: str
    parent_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    storage_id: str
    metadata: Dict[str, Any] = {}
    type: Literal['file']

class ItemSearchResultDirectory(BaseModel):
    id: str  # UUID
    name: str
    parent_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    type: Literal['directory']

class ItemSearchResponse(BaseModel):
    directories: List[ItemSearchResultDirectory]
    files: List[ItemSearchResultFile]


