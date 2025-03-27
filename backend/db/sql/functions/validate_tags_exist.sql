/*
 * Function: validate_tags_exist
 *
 * Ensures that a set of tags exists in the database for a specific user, creating any missing tags
 * as needed. This function provides an idempotent way to manage tags, handling both creation of
 * new tags and retrieval of existing ones in a single operation.
 *
 * Parameters:
 *   - p_tag_names (TEXT[]): Array of tag names to ensure exist
 *     * Case-sensitive tag names
 *     * Duplicates in the input array are automatically handled
 *   - p_user_token (TEXT): The user token for access control and ownership assignment
 *
 * Returns:
 *   TABLE:
 *     - id (INTEGER): The unique identifier of each tag
 *     - name (TEXT): The name of each tag
 *   Note: Returns both newly created and existing tags that match the input names
 *
 * Implementation Notes:
 *   - Uses UPSERT pattern (INSERT ... ON CONFLICT) for efficient handling
 *   - Maintains user-specific tag namespaces
 *   - Handles duplicate input tag names automatically
 *   - Creates missing tags atomically
 *   - Returns results in a deterministic order
 *   - Transaction safe
 *
 * Examples:
 *   -- Create/get multiple tags at once
 *   SELECT * FROM validate_tags_exist(
 *     ARRAY['python', 'coding', 'web'],  -- tag names to ensure exist
 *     'user123'                          -- user token
 *   );
 *
 *   -- Example result:
 *   --  id  |  name
 *   -- -----+--------
 *   --   1  | python
 *   --   2  | coding
 *   --   3  | web
 */
CREATE OR REPLACE FUNCTION validate_tags_exist(
    p_tag_names TEXT[],
    p_user_token TEXT DEFAULT 'public'
) RETURNS TABLE (id INTEGER, name TEXT) AS $$
BEGIN
    RETURN QUERY
    WITH new_tags AS (
        INSERT INTO tags (name, user_token)
        SELECT DISTINCT unnest(p_tag_names), p_user_token
        ON CONFLICT ON CONSTRAINT tags_name_user_token_key DO NOTHING
        RETURNING tags.id, tags.name
    )
    SELECT t.id, t.name
    FROM (
        SELECT nt.id, nt.name
        FROM new_tags nt
        UNION
        SELECT tg.id, tg.name
        FROM tags tg
        WHERE tg.name = ANY(p_tag_names)
            AND tg.user_token = p_user_token
    ) t;
END;
$$ LANGUAGE plpgsql;