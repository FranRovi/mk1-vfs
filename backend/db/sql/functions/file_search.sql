/*
 * Function: file_search
 *
 * Searches for files based on multiple criteria including name, location, tags, and metadata.
 *
 * Parameters:
 *   - p_query (TEXT): Optional text to search in file names (case-insensitive, uses LIKE)
 *   - p_parent_id (UUID): Optional parent directory UUID to limit search scope
 *   - p_tag_names (TEXT[]): Optional array of tag names to filter files (all must match)
 *   - p_metadata_filters (JSONB): Optional metadata criteria (all must match)
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns: JSON array of matching files
 */
CREATE OR REPLACE FUNCTION file_search(
    p_query TEXT DEFAULT NULL,
    p_parent_id UUID DEFAULT NULL,
    p_tag_names TEXT[] DEFAULT NULL,
    p_metadata_filters JSONB DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS JSON AS $$
DECLARE
    v_name_pattern TEXT;
    file_result JSON;
BEGIN
    -- Prepare name search pattern if query provided
    IF p_query IS NOT NULL THEN
        v_name_pattern := '%' || p_query || '%';
    END IF;

    WITH matching_files AS (
        SELECT DISTINCT
            f.id,
            f.name,
            f.parent_id,
            f.created_at,
            f.updated_at,
            f.storage_id,
            f.metadata
        FROM files f
        -- Join with tags if tag filter is provided
        LEFT JOIN file_tags ft ON f.id = ft.file_id
        LEFT JOIN tags t ON ft.tag_id = t.id AND t.user_token = p_user_token
        WHERE f.user_token = p_user_token
            AND (p_parent_id IS NULL OR f.parent_id = p_parent_id)
            AND (
                p_query IS NULL
                OR f.name ILIKE v_name_pattern
            )
            -- Tag filter
            AND (
                p_tag_names IS NULL
                OR t.name = ANY(p_tag_names)
            )
            -- Metadata filter
            AND (
                p_metadata_filters IS NULL
                OR f.metadata @> p_metadata_filters
            )
        GROUP BY
            f.id,
            f.name,
            f.parent_id,
            f.created_at,
            f.updated_at,
            f.storage_id,
            f.metadata
        -- If tags specified, ensure all required tags are present
        HAVING
            p_tag_names IS NULL
            OR array_length(p_tag_names, 1) = count(DISTINCT t.name)
        ORDER BY f.name
    )
    SELECT json_agg(
        json_build_object(
            'id', id,
            'name', name,
            'parent_id', parent_id,
            'created_at', created_at,
            'updated_at', updated_at,
            'storage_id', storage_id,
            'metadata', metadata,
            'type', 'file'
        )
    )
    INTO file_result
    FROM matching_files;

    RETURN COALESCE(file_result, '[]'::JSON);
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION file_search(TEXT, UUID, TEXT[], JSONB, TEXT) IS
'Searches for files based on multiple criteria.
Parameters:
  - p_query: Text to search in names (optional, case-insensitive)
  - p_parent_id: Limit search to items in this directory (optional)
  - p_tag_names: Array of tag names to filter by (optional, all must match)
  - p_metadata_filters: JSONB object with metadata criteria (optional)
  - p_user_token: User token for access control
Returns: JSON array of matching files';