/*
 * Function: file_tags_manage
 *
 * Manages the tags associated with a file through various operations (add, remove, or set).
 * This function provides a comprehensive way to manipulate file tags by delegating to specialized
 * functions while ensuring data consistency and proper access control.
 *
 * Parameters:
 *   - p_file_id (UUID): The UUID of the file to manage tags for
 *   - p_tag_names (TEXT[]): Array of tag names to process
 *   - p_operation (TEXT): The operation to perform, must be one of:
 *     * 'add': Add new tags while preserving existing ones
 *     * 'remove': Remove specified tags while keeping others
 *     * 'set': Replace all existing tags with the specified ones
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
 *   - P0001: Invalid operation type (must be 'add', 'remove', or 'set')
 *   - P0002: File not found or access denied
 *
 * Implementation Notes:
 *   - Delegates to specialized functions:
 *     * file_tags_add: For adding new tags
 *     * file_tags_remove: For removing tags
 *     * file_tags_set: For replacing all tags
 *   - All operations maintain the same behavior as before
 *   - All operations are atomic (transaction-based)
 *   - Returns alphabetically sorted tag lists
 *
 * Examples:
 *   -- Add new tags while keeping existing ones
 *   SELECT * FROM file_tags_manage(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- file UUID
 *     ARRAY['document', 'important'],           -- tags to add
 *     'add',                                    -- operation
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Remove specific tags
 *   SELECT * FROM file_tags_manage(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- file UUID
 *     ARRAY['temporary'],                       -- tags to remove
 *     'remove',                                 -- operation
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Replace all tags with new ones
 *   SELECT * FROM file_tags_manage(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- file UUID
 *     ARRAY['final', 'reviewed'],              -- new tags
 *     'set',                                    -- operation
 *     'user123'                                 -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION file_tags_manage(
    p_file_id UUID,
    p_tag_names TEXT[],
    p_operation TEXT,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (tags JSON) AS $$
BEGIN
    -- Validate operation parameter
    IF p_operation NOT IN ('add', 'remove', 'set') THEN
        RAISE EXCEPTION 'Invalid operation. Must be one of: add, remove, set'
            USING ERRCODE = 'P0001';
    END IF;

    -- Delegate to the appropriate specialized function based on operation
    RETURN QUERY
    SELECT CASE p_operation
        WHEN 'add' THEN
            (SELECT * FROM file_tags_add(p_file_id, p_tag_names, p_user_token))
        WHEN 'remove' THEN
            (SELECT * FROM file_tags_remove(p_file_id, p_tag_names, p_user_token))
        WHEN 'set' THEN
            (SELECT * FROM file_tags_set(p_file_id, p_tag_names, p_user_token))
    END;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION file_tags_manage(UUID, TEXT[], TEXT, TEXT) IS
'Manages tags for a file (add, remove, or set tags) by delegating to specialized functions.
Parameters:
  - p_file_id: UUID of the file to manage tags for
  - p_tag_names: Array of tag names to add, remove, or set
  - p_operation: Operation to perform ("add", "remove", or "set")
  - p_user_token: User token for access control
Returns:
  - tags: JSON object with structure:
    {
      names: string[],
      ids: integer[]
    }
Raises:
  - P0001: Invalid operation type
  - P0002: File not found or access denied
Notes:
  - Delegates to specialized functions for each operation type
  - All operations are atomic (transaction)
  - Returns complete list of file''s tags after operation
  - Tags are ordered alphabetically by name';