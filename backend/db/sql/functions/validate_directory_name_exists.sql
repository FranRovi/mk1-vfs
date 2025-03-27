/*
 * Function: validate_directory_name_exists
 *
 * Checks if a directory name would conflict with an existing directory in the same parent directory
 * for a specific user. This is used to prevent duplicate directory names within the same level of
 * the directory hierarchy.
 *
 * Parameters:
 *   - p_name (TEXT): The name of the directory to check
 *   - p_parent_id (UUID): The ID of the parent directory. NULL for root directories
 *   - p_user_token (TEXT): The user token for ownership validation
 *   - p_exclude_id (UUID): Optional. ID of a directory to exclude from the check (useful for updates)
 *
 * Returns:
 *   BOOLEAN: TRUE if a conflict exists, FALSE otherwise
 *
 * Examples:
 *   -- Check if 'Documents' exists in root directory
 *   SELECT validate_directory_name_exists('Documents', NULL, 'user123');
 *
 *   -- Check if 'Photos' exists in parent directory (excluding current directory during update)
 *   SELECT validate_directory_name_exists('Photos', '123e4567-e89b-12d3-a456-426614174000', 'user123', '987fcdeb-51k2-12d3-a456-426614174000');
 */

CREATE OR REPLACE FUNCTION validate_directory_name_exists(
    p_name TEXT,
    p_parent_id UUID,
    p_user_token TEXT DEFAULT 'public',
    p_exclude_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM directories
        WHERE name = p_name
            AND COALESCE(parent_id, UUID_NIL()) = COALESCE(p_parent_id, UUID_NIL())
            AND user_token = p_user_token
            AND (p_exclude_id IS NULL OR id != p_exclude_id)
    );
END;
$$ LANGUAGE plpgsql;