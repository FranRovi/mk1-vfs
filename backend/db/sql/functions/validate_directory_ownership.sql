/*
 * Function: validate_directory_ownership
 *
 * Validates whether a directory belongs to a specific user by checking ownership through
 * the user token. This function provides a simple but essential security check used by
 * other functions to ensure proper access control.
 *
 * Parameters:
 *   - p_directory_id (UUID): The UUID of the directory to validate ownership for
 *   - p_user_token (TEXT): The user token to check ownership against
 *
 * Returns:
 *   BOOLEAN:
 *     - TRUE if the directory exists and belongs to the specified user
 *     - FALSE if the directory doesn't exist or belongs to a different user
 *
 * Implementation Notes:
 *   - Simple existence check combining directory ID and user token
 *   - Returns FALSE for non-existent directories (no distinction from access denied)
 *   - Used internally by other functions for access control
 *   - No exceptions are raised (boolean result only)
 *   - Fast and efficient (uses indexed columns)
 *
 * Examples:
 *   -- Check if user owns a directory
 *   SELECT validate_directory_ownership(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- directory UUID
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Example usage in another function
 *   IF NOT validate_directory_ownership(some_directory_id, user_token) THEN
 *     RAISE EXCEPTION 'Directory not found or access denied'
 *       USING ERRCODE = 'P0002';
 *   END IF;
 */

CREATE OR REPLACE FUNCTION validate_directory_ownership(
    p_directory_id UUID,
    p_user_token TEXT DEFAULT 'public'
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM directories
        WHERE id = p_directory_id
            AND user_token = p_user_token
    );
END;
$$ LANGUAGE plpgsql;