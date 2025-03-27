/*
 * Function: file_tags_remove
 *
 * Removes specified tags from a file while keeping others.
 *
 * Parameters:
 *   - p_file_id (UUID): The UUID of the file to remove tags from
 *   - p_tag_names (TEXT[]): Array of tag names to remove
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   TABLE (tags JSON): JSON object containing the updated tag list:
 *     {
 *       "names": string[],   // Array of tag names (sorted alphabetically)
 *       "ids": integer[]     // Array of tag IDs (matching names array order)
 *     }
 *
 * Error Conditions:
 *   - P0002: File not found or access denied
 *
 * Implementation Notes:
 *   - Validates file ownership via user_token
 *   - Silently ignores non-existent tags
 *   - All operations are atomic (transaction-based)
 *   - Returns alphabetically sorted tag lists
 */

CREATE OR REPLACE FUNCTION file_tags_remove(
    p_file_id UUID,
    p_tag_names TEXT[],
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (tags JSON) AS $$
DECLARE
    result JSON;
BEGIN
    -- Validate file exists and belongs to user
    IF NOT validate_file_ownership(p_file_id, p_user_token) THEN
        RAISE EXCEPTION 'File not found or access denied'
            USING ERRCODE = 'P0002';
    END IF;

    -- Start transaction for the entire operation
    BEGIN
        -- Remove specified tags
        DELETE FROM file_tags ft
        USING tags t
        WHERE ft.file_id = p_file_id
            AND ft.tag_id = t.id
            AND t.name = ANY(p_tag_names)
            AND t.user_token = p_user_token;

        -- Get updated tags
        WITH file_tags_result AS (
            SELECT
                array_agg(t.name ORDER BY t.name) as tag_names,
                array_agg(t.id ORDER BY t.name) as tag_ids
            FROM file_tags ft
            INNER JOIN tags t ON t.id = ft.tag_id
            WHERE ft.file_id = p_file_id
                AND t.user_token = p_user_token
            GROUP BY ft.file_id
        )
        SELECT json_build_object(
            'names', COALESCE((SELECT tag_names FROM file_tags_result), ARRAY[]::TEXT[]),
            'ids', COALESCE((SELECT tag_ids FROM file_tags_result), ARRAY[]::INTEGER[])
        ) INTO result;

        RETURN QUERY SELECT result;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION file_tags_remove(UUID, TEXT[], TEXT) IS
'Removes specified tags from a file while keeping others.
Parameters:
  - p_file_id: UUID of the file to remove tags from
  - p_tag_names: Array of tag names to remove
  - p_user_token: User token for access control
Returns:
  - tags: JSON object with structure: { names: string[], ids: integer[] }
Notes:
  - Silently ignores non-existent tags
  - Preserves unspecified tags
  - All operations are atomic (transaction)
  - Returns complete list of file''s tags after operation
  - Tags are ordered alphabetically by name';