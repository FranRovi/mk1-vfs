/*
 * Function: directory_details
 *
 * Retrieves detailed information about a specific directory, including its metadata and child item counts.
 * This function provides a comprehensive view of a directory's properties and its immediate contents
 * statistics while ensuring proper access control.
 *
 * Parameters:
 *   - p_directory_id (UUID): The UUID of the directory to get details for
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   TABLE (directory_details JSON): JSON object containing:
 *     {
 *       "id": UUID,            // Directory's unique identifier
 *       "name": string,        // Directory name
 *       "created_at": timestamp,// Creation timestamp
 *       "updated_at": timestamp,// Last modification timestamp
 *       "parent_id": UUID,     // Parent directory ID (null for root)
 *       "child_counts": {
 *         "directories": integer,// Number of subdirectories
 *         "files": integer,     // Number of files
 *         "total": integer      // Total number of items
 *       }
 *     }
 *   Note: Returns NULL if directory not found or access denied
 *
 * Implementation Notes:
 *   - Validates directory ownership via user_token
 *   - Counts only immediate children (not recursive)
 *   - Includes both basic metadata and computed statistics
 *   - Uses CTEs for efficient counting of child items
 *   - Returns NULL instead of raising an exception for not found/access denied
 *   - Only counts children owned by the same user
 *
 * Examples:
 *   -- Get details of a specific directory
 *   SELECT * FROM directory_details(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- directory UUID
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Example result:
 *   -- {
 *   --   "id": "123e4567-e89b-12d3-a456-426614174000",
 *   --   "name": "Documents",
 *   --   "created_at": "2024-01-15T10:30:00Z",
 *   --   "updated_at": "2024-01-15T14:45:00Z",
 *   --   "parent_id": "987fcdeb-51k2-12d3-a456-426614174000",
 *   --   "child_counts": {
 *   --     "directories": 3,
 *   --     "files": 5,
 *   --     "total": 8
 *   --   }
 *   -- }
 */

CREATE OR REPLACE FUNCTION directory_details(
    p_directory_id UUID DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (directory_details JSON) AS $$
DECLARE
    result JSON;
BEGIN
    WITH directory_counts AS (
        SELECT
            COUNT(d.id) as directory_count,
            COUNT(f.id) as file_count
        FROM directories dir
        LEFT JOIN directories d ON d.parent_id = dir.id AND d.user_token = p_user_token
        LEFT JOIN files f ON f.parent_id = dir.id AND f.user_token = p_user_token
        WHERE dir.id = p_directory_id
            AND dir.user_token = p_user_token
    )
    SELECT json_build_object(
        'id', d.id,
        'name', d.name,
        'created_at', d.created_at,
        'updated_at', d.updated_at,
        'parent_id', d.parent_id,
        'child_counts', json_build_object(
            'directories', COALESCE(dc.directory_count, 0),
            'files', COALESCE(dc.file_count, 0),
            'total', COALESCE(dc.directory_count + dc.file_count, 0)
        )
    ) INTO result
    FROM directories d
    LEFT JOIN directory_counts dc ON true
    WHERE d.id = p_directory_id
        AND d.user_token = p_user_token;

    -- If directory not found or wrong user_token, return NULL
    IF result IS NULL THEN
        RETURN QUERY SELECT NULL::JSON;
        RETURN;
    END IF;

    RETURN QUERY SELECT result;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION directory_details(UUID, TEXT) IS
'Retrieves detailed information about a specific directory.
Parameters:
  - p_directory_id: UUID of the directory to get details for
  - p_user_token: User token for access control
Returns:
  - directory_details: JSON object with structure:
    {
      id: UUID,
      name: string,
      created_at: timestamp,
      updated_at: timestamp,
      parent_id: UUID,
      child_counts: {
        directories: integer,
        files: integer,
        total: integer
      }
    }
Returns NULL if directory not found or user_token does not match.';

-- Example usage:
-- SELECT * FROM directory_details('some-uuid', 'user123');