/*
 * Function: directory_search
 *
 * Searches for directories based on name pattern and parent directory.
 *
 * Parameters:
 *   - p_query (TEXT): Optional text to search in directory names (case-insensitive, uses LIKE)
 *   - p_parent_id (UUID): Optional parent directory UUID to limit search scope
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns: JSON array of matching directories
 */
CREATE OR REPLACE FUNCTION directory_search(
    p_query TEXT DEFAULT NULL,
    p_parent_id UUID DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS JSON AS $$
DECLARE
    v_name_pattern TEXT;
    dir_result JSON;
BEGIN
    -- Prepare name search pattern if query provided
    IF p_query IS NOT NULL THEN
        v_name_pattern := '%' || p_query || '%';
    END IF;

    WITH matching_directories AS (
        SELECT
            d.id,
            d.name,
            d.parent_id,
            d.created_at,
            d.updated_at
        FROM directories d
        WHERE d.user_token = p_user_token
            AND (p_parent_id IS NULL OR d.parent_id = p_parent_id)
            AND (
                p_query IS NULL
                OR d.name ILIKE v_name_pattern
            )
        ORDER BY d.name
    )
    SELECT json_agg(
        json_build_object(
            'id', id,
            'name', name,
            'parent_id', parent_id,
            'created_at', created_at,
            'updated_at', updated_at,
            'type', 'directory'
        )
    )
    INTO dir_result
    FROM matching_directories;

    RETURN COALESCE(dir_result, '[]'::JSON);
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION directory_search(TEXT, UUID, TEXT) IS
'Searches for directories based on name pattern and parent directory.
Parameters:
  - p_query: Text to search in names (optional, case-insensitive)
  - p_parent_id: Limit search to items in this directory (optional)
  - p_user_token: User token for access control
Returns: JSON array of matching directories';