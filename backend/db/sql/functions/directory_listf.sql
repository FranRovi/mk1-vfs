/*
 * Function: directory_listf
 *
 * Lists all files within a specified parent directory (or root level).
 * This function provides a flat listing of immediate file children while
 * ensuring proper access control.
 *
 * Parameters:
 *   - p_parent_id (UUID): The UUID of the parent directory to list contents from (NULL for root level)
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   JSON: Array of file objects:
 *     [
 *       {
 *         "id": UUID,            // File's unique identifier
 *         "name": string,        // File name
 *         "created_at": timestamp // Creation timestamp
 *       },
 *       ...
 *     ]
 *   Note: Array is sorted by name and returns empty array if no files exist
 *
 * Implementation Notes:
 *   - Lists only immediate children (non-recursive)
 *   - Validates ownership via user_token
 *   - Handles root level listing (parent_id = NULL)
 *   - Returns empty array instead of NULL for no results
 *   - Orders items alphabetically by name
 *   - Returns minimal file details for efficient listing
 *
 * Examples:
 *   -- List files at root level
 *   SELECT * FROM directory_listf(
 *     NULL,      -- root level
 *     'user123'  -- user token
 *   );
 *
 *   -- List files in a specific directory
 *   SELECT * FROM directory_listf(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- parent directory UUID
 *     'user123'                                 -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION directory_listf(
    p_parent_id UUID DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS JSON AS $$
DECLARE
    file_result JSON;
BEGIN
    -- Get files
    SELECT json_agg(file_data)
    INTO file_result
    FROM (
        SELECT
            id,
            name,
            created_at
        FROM files
        WHERE
            user_token = p_user_token
            AND (
                (p_parent_id IS NULL AND parent_id IS NULL)
                OR parent_id = p_parent_id
            )
        ORDER BY name
    ) file_data;

    -- Handle NULL result (empty array instead of NULL)
    RETURN COALESCE(file_result, '[]'::JSON);
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION directory_listf(UUID, TEXT) IS
'Lists all files within a given parent directory (or root if parent_id is null).
Parameters:
  - p_parent_id: UUID of the parent directory (NULL for root level)
  - p_user_token: User token for access control
Returns: JSON array of {id, name, created_at} for files';