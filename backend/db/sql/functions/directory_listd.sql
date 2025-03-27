/*
 * Function: directory_listd
 *
 * Lists all directories within a specified parent directory (or root level).
 * This function provides a flat listing of immediate directory children while
 * ensuring proper access control.
 *
 * Parameters:
 *   - p_parent_id (UUID): The UUID of the parent directory to list contents from (NULL for root level)
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   JSON: Array of directory objects:
 *     [
 *       {
 *         "id": UUID,            // Directory's unique identifier
 *         "name": string,        // Directory name
 *         "created_at": timestamp // Creation timestamp
 *       },
 *       ...
 *     ]
 *   Note: Array is sorted by name and returns empty array if no directories exist
 *
 * Implementation Notes:
 *   - Lists only immediate children (non-recursive)
 *   - Validates ownership via user_token
 *   - Handles root level listing (parent_id = NULL)
 *   - Returns empty array instead of NULL for no results
 *   - Orders items alphabetically by name
 *   - Returns minimal directory details for efficient listing
 *
 * Examples:
 *   -- List directories at root level
 *   SELECT * FROM directory_listd(
 *     NULL,      -- root level
 *     'user123'  -- user token
 *   );
 *
 *   -- List directories in a specific directory
 *   SELECT * FROM directory_listd(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- parent directory UUID
 *     'user123'                                 -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION directory_listd(
    p_parent_id UUID DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS JSON AS $$
DECLARE
    dir_result JSON;
BEGIN
    -- Get directories
    SELECT json_agg(dir_data)
    INTO dir_result
    FROM (
        SELECT
            id,
            name,
            created_at
        FROM directories
        WHERE
            user_token = p_user_token
            AND (
                (p_parent_id IS NULL AND parent_id IS NULL)
                OR parent_id = p_parent_id
            )
        ORDER BY name
    ) dir_data;

    -- Handle NULL result (empty array instead of NULL)
    RETURN COALESCE(dir_result, '[]'::JSON);
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION directory_listd(UUID, TEXT) IS
'Lists all directories within a given parent directory (or root if parent_id is null).
Parameters:
  - p_parent_id: UUID of the parent directory (NULL for root level)
  - p_user_token: User token for access control
Returns: JSON array of {id, name, created_at} for directories';