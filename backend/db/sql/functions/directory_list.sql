/*
 * Function: directory_list
 *
 * Lists all directories and files within a specified parent directory (or root level), returning
 * them as separate arrays. This function provides a flat listing of immediate children while
 * ensuring proper access control.
 *
 * Parameters:
 *   - p_parent_id (UUID): The UUID of the parent directory to list contents from (NULL for root level)
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   TABLE:
 *     - directories (JSON): Array of directory objects from directory_listd
 *     - files (JSON): Array of file objects from directory_listf
 *
 * Implementation Notes:
 *   - Combines results from directory_listd and directory_listf
 *   - Lists only immediate children (non-recursive)
 *   - Validates ownership via user_token
 *   - Handles root level listing (parent_id = NULL)
 *   - Returns empty arrays instead of NULL for no results
 *   - Orders items alphabetically by name
 *
 * Examples:
 *   -- List directories and files at root level
 *   SELECT * FROM directory_list(
 *     NULL,      -- root level
 *     'user123'  -- user token
 *   );
 *
 *   -- List directories and files in a specific directory
 *   SELECT * FROM directory_list(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- parent directory UUID
 *     'user123'                                 -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION directory_list(
    p_parent_id UUID DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (
    directories JSON,
    files JSON
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        directory_listd(p_parent_id, p_user_token) AS directories,
        directory_listf(p_parent_id, p_user_token) AS files;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION directory_list(UUID, TEXT) IS
'Lists all directories and files within a given parent directory (or root if parent_id is null).
Parameters:
  - p_parent_id: UUID of the parent directory (NULL for root level)
  - p_user_token: User token for access control
Returns:
  - directories: JSON array of {id, name, created_at} for directories
  - files: JSON array of {id, name, created_at} for files';