/*
 * Function: item_search
 *
 * Performs a flexible search across files and directories based on multiple criteria.
 * This is a wrapper function that combines results from file_search and directory_search.
 *
 * Parameters:
 *   - p_query (TEXT): Optional text to search in item names (case-insensitive, uses LIKE)
 *   - p_type (TEXT): Type of items to search for ('all', 'file', or 'directory')
 *   - p_parent_id (UUID): Optional parent directory UUID to limit search scope
 *   - p_tag_names (TEXT[]): Optional array of tag names to filter files (all must match)
 *   - p_metadata_filters (JSONB): Optional metadata criteria (all must match)
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   TABLE:
 *     - directories (JSON): Array of matching directories
 *     - files (JSON): Array of matching files
 *
 * Example usage:
 *   SELECT * FROM item_search(
 *     'query',
 *     'all',
 *     'parent_id',
 *     ARRAY['tag1', 'tag2'],
 *     '{"key1": "value1", "key2": "value2"}',
 *     'user_token'
 *   );
 */
 
CREATE OR REPLACE FUNCTION item_search(
    p_query TEXT DEFAULT NULL,
    p_type TEXT DEFAULT 'all',
    p_parent_id UUID DEFAULT NULL,
    p_tag_names TEXT[] DEFAULT NULL,
    p_metadata_filters JSONB DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (
    directories JSON,
    files JSON
) AS $$
DECLARE
    dir_result JSON;
    file_result JSON;
BEGIN
    -- Validate type parameter
    IF p_type NOT IN ('all', 'file', 'directory') THEN
        RAISE EXCEPTION 'Invalid type parameter. Must be one of: all, file, directory'
            USING ERRCODE = 'P0001';
    END IF;

    -- Get directories if needed
    IF p_type IN ('all', 'directory') THEN
        dir_result := directory_search(p_query, p_parent_id, p_user_token);
    ELSE
        dir_result := '[]'::JSON;
    END IF;

    -- Get files if needed
    IF p_type IN ('all', 'file') THEN
        file_result := file_search(p_query, p_parent_id, p_tag_names, p_metadata_filters, p_user_token);
    ELSE
        file_result := '[]'::JSON;
    END IF;

    RETURN QUERY SELECT dir_result AS directories, file_result AS files;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION item_search(TEXT, TEXT, UUID, TEXT[], JSONB, TEXT) IS
'Searches for both files and directories based on multiple criteria.
Parameters:
  - p_query: Text to search in names (optional, case-insensitive)
  - p_type: Type of items to search ("all", "file", or "directory")
  - p_parent_id: Limit search to items in this directory (optional)
  - p_tag_names: Array of tag names to filter files by (optional)
  - p_metadata_filters: JSONB object with metadata criteria (optional)
  - p_user_token: User token for access control
Returns: Table with two JSON columns:
  - directories: Array of matching directories
  - files: Array of matching files';