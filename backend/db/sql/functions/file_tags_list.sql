/*
 * Function: file_tags_list
 *
 * Retrieves all tags associated with a specific file.
 *
 * Parameters:
 *   - p_file_id (UUID): The UUID of the file to get tags for
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   TABLE (tags JSON): JSON object containing:
 *     {
 *       "names": string[],   // Array of tag names (sorted alphabetically)
 *       "ids": integer[]     // Array of tag IDs (matching names array order)
 *     }
 *   Note: Returns NULL if file not found or access denied
 *
 * Implementation Notes:
 *   - Validates file ownership via user_token
 *   - Returns tags sorted alphabetically by name
 *   - Returns empty arrays if file has no tags
 *   - Returns NULL if file not found or access denied
 *
 * Example usage:
 *   SELECT * FROM file_tags_list('file-uuid', 'user123');
 *
 */
CREATE OR REPLACE FUNCTION file_tags_list(
    p_file_id UUID,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (tags JSON) AS $$
DECLARE
    result JSON;
BEGIN
    -- First validate file ownership
    IF NOT validate_file_ownership(p_file_id, p_user_token) THEN
        RETURN QUERY SELECT NULL::JSON;
        RETURN;
    END IF;

    WITH file_tags AS (
        -- Get all tags for the file
        SELECT
            array_agg(t.name ORDER BY t.name) as tag_names,
            array_agg(t.id ORDER BY t.name) as tag_ids
        FROM files f
        LEFT JOIN file_tags ft ON ft.file_id = f.id
        LEFT JOIN tags t ON t.id = ft.tag_id AND t.user_token = p_user_token
        WHERE f.id = p_file_id
            AND f.user_token = p_user_token
        GROUP BY f.id
    )
    SELECT json_build_object(
        'names', COALESCE(ft.tag_names, ARRAY[]::TEXT[]),
        'ids', COALESCE(ft.tag_ids, ARRAY[]::INTEGER[])
    ) INTO result
    FROM file_tags ft;

    RETURN QUERY SELECT COALESCE(result, json_build_object(
        'names', ARRAY[]::TEXT[],
        'ids', ARRAY[]::INTEGER[]
    ));
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION file_tags_list(UUID, TEXT) IS
'Retrieves all tags associated with a specific file.
Parameters:
  - p_file_id: UUID of the file to get tags for
  - p_user_token: User token for access control
Returns:
  - tags: JSON object with structure:
    {
      names: string[],
      ids: integer[]
    }
Returns NULL if file not found or user_token does not match.';
