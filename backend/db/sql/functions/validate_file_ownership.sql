/*
 * Function: validate_file_ownership
 *
 * Validates whether a file belongs to a specific user by checking ownership through
 * the user token. This function provides a simple but essential security check used by
 * other functions to ensure proper access control.
 *
 * Parameters:
 *   - p_file_id (UUID): The UUID of the file to validate ownership for
 *   - p_user_token (TEXT): The user token to check ownership against
 *
 * Returns:
 *   BOOLEAN:
 *     - TRUE if the file exists and belongs to the specified user
 *     - FALSE if the file doesn't exist or belongs to a different user
 *
 * Implementation Notes:
 *   - Simple existence check combining file ID and user token
 *   - Returns FALSE for non-existent files (no distinction from access denied)
 *   - Used internally by other functions for access control
 *   - No exceptions are raised (boolean result only)
 *   - Fast and efficient (uses indexed columns)
 *
 * Examples:
 *   -- Check if user owns a file
 *   SELECT validate_file_ownership(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- file UUID
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Example usage in another function
 *   IF NOT validate_file_ownership(some_file_id, user_token) THEN
 *     RAISE EXCEPTION 'File not found or access denied'
 *       USING ERRCODE = 'P0002';
 *   END IF;
 */

CREATE OR REPLACE FUNCTION validate_file_ownership(
    p_file_id UUID,
    p_user_token TEXT DEFAULT 'public'
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM files
        WHERE id = p_file_id
            AND user_token = p_user_token
    );
END;
$$ LANGUAGE plpgsql;