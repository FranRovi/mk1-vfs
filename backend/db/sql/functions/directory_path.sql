/*
 * Function: directory_path
 *
 * Retrieves the complete path information for a directory, including both names and IDs of all
 * directories in the path from root to the target directory. This function traverses the directory
 * tree upwards to construct the full path while ensuring proper access control.
 *
 * Parameters:
 *   - p_directory_id (UUID): The UUID of the directory to get the path for
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   JSON object containing:
 *     {
 *       "names": text[],     // Array of directory names from root to target
 *       "ids": uuid[]        // Array of directory UUIDs from root to target
 *     }
 *   Note: Arrays are ordered from root to target directory (top-down)
 *   Returns empty arrays if directory not found or access denied
 *
 * Implementation Notes:
 *   - Uses recursive CTE to traverse directory hierarchy upwards
 *   - Validates ownership at each level via user_token
 *   - Maintains parallel arrays for names and IDs
 *   - Arrays are ordered from root to leaf (e.g., ["root", "docs", "project"])
 *   - Returns empty arrays instead of NULL for not found/access denied cases
 *   - Handles root directories (no parent) correctly
 *
 * Examples:
 *   -- Get path for a nested directory
 *   SELECT directory_path(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- directory UUID
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Example result:
 *   -- {
 *   --   "names": ["Documents", "Projects", "Backend"],
 *   --   "ids": [
 *   --     "111e4567-e89b-12d3-a456-426614174000",
 *   --     "222e4567-e89b-12d3-a456-426614174000",
 *   --     "123e4567-e89b-12d3-a456-426614174000"
 *   --   ]
 *   -- }
 */

CREATE OR REPLACE FUNCTION directory_path(
    p_directory_id UUID DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public'
) RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    WITH RECURSIVE parent_dirs AS (
        -- Base case: start with the current directory
        SELECT
            id,
            name,
            parent_id,
            ARRAY[name] as path_names,
            ARRAY[id] as path_ids,
            1 as depth
        FROM directories
        WHERE id = p_directory_id
            AND user_token = p_user_token

        UNION ALL

        -- Recursive case: get all parents up to root
        SELECT
            d.id,
            d.name,
            d.parent_id,
            array_append(p.path_names, d.name),
            array_append(p.path_ids, d.id),
            p.depth + 1
        FROM directories d
        INNER JOIN parent_dirs p ON d.id = p.parent_id
        WHERE d.user_token = p_user_token
    )
    SELECT json_build_object(
        'names', COALESCE(
            (SELECT path_names FROM parent_dirs ORDER BY depth DESC LIMIT 1),
            ARRAY[]::TEXT[]
        ),
        'ids', COALESCE(
            (SELECT path_ids FROM parent_dirs ORDER BY depth DESC LIMIT 1),
            ARRAY[]::UUID[]
        )
    ) INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;