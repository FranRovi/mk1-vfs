/*
 * Function: tags_list
 *
 * Retrieves all tags associated with a specific user from the database. The function returns
 * a sorted list of tags with their IDs and names, providing a comprehensive view of a user's
 * tag namespace.
 *
 * Parameters:
 *   - p_user_token (TEXT): The user token for filtering tags
 *     * Defaults to 'public' if not specified
 *     * Case-sensitive matching
 *
 * Returns:
 *   TABLE:
 *     - id (INTEGER): The unique identifier of each tag
 *     - name (TEXT): The name of each tag
 *   Note: Results are ordered alphabetically by tag name for consistent retrieval
 *
 * Implementation Notes:
 *   - Filters tags by user_token
 *   - Returns results in alphabetical order by tag name
 *   - Transaction safe
 *   - Efficient index-based lookup
 *
 * Examples:
 *   -- List all tags for a specific user
 *   SELECT * FROM tags_list('user123');
 *
 *   -- Example result:
 *   --  id  |  name
 *   -- -----+--------
 *   --   2  | coding
 *   --   1  | python
 *   --   3  | web
 */
CREATE OR REPLACE FUNCTION tags_list(
    p_user_token TEXT DEFAULT 'public'
) RETURNS TABLE (id INTEGER, name TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT t.id, t.name
    FROM tags t
    WHERE t.user_token = p_user_token
    ORDER BY t.name ASC;
END;
$$ LANGUAGE plpgsql;