/*
 * Function: validate_file_name_exists
 *
 * Checks if a file name would conflict with an existing file in the same directory
 * for a specific user. This function prevents duplicate file names within the same
 * directory, ensuring unique file names at each directory level.
 *
 * Parameters:
 *   - p_name (TEXT): The name of the file to check
 *   - p_parent_id (UUID): The ID of the directory containing the file. NULL for root directory
 *   - p_user_token (TEXT): The user token for ownership validation
 *   - p_exclude_id (UUID): Optional. ID of a file to exclude from the check (useful for file renames)
 *
 * Returns:
 *   BOOLEAN: TRUE if a name conflict exists, FALSE otherwise
 *
 * Examples:
 *   -- Check if 'document.pdf' exists in root directory
 *   SELECT validate_file_name_exists('document.pdf', NULL, 'user123');
 *
 *   -- Check if 'report.docx' exists in a specific directory (excluding the current file during rename)
 *   SELECT validate_file_name_exists('report.docx', '123e4567-e89b-12d3-a456-426614174000', 'user123', '987fcdeb-51k2-12d3-a456-426614174000');
 */

CREATE OR REPLACE FUNCTION validate_file_name_exists(
    p_name TEXT,
    p_parent_id UUID,
    p_user_token TEXT DEFAULT 'public',
    p_exclude_id UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM files
        WHERE name = p_name
            AND COALESCE(parent_id, UUID_NIL()) = COALESCE(p_parent_id, UUID_NIL())
            AND user_token = p_user_token
            AND (p_exclude_id IS NULL OR id != p_exclude_id)
    );
END;
$$ LANGUAGE plpgsql;