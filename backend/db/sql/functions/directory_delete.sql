/*
 * Function: directory_delete
 *
 * Deletes a directory from the virtual file system, with optional recursive deletion of its contents.
 * This function provides both safe deletion of empty directories and recursive deletion of directory
 * trees while maintaining proper access control and data consistency.
 *
 * Parameters:
 *   - p_directory_id (UUID): The UUID of the directory to delete
 *   - p_recursive (BOOLEAN): Whether to recursively delete all contents
 *     * true: Delete directory and all its contents (subdirectories and files)
 *     * false: Only delete if directory is empty, fail otherwise
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   VOID
 *
 * Error Conditions:
 *   - P0002: Directory not found or access denied
 *   - P0001: Operation failed due to one of these reasons:
 *     * Directory contains subdirectories (non-recursive mode)
 *     * Directory contains files (non-recursive mode)
 *     * Deletion operation failed
 *
 * Implementation Notes:
 *   - Validates directory existence and ownership before deletion
 *   - In non-recursive mode:
 *     * Verifies directory is empty (no subdirectories or files)
 *     * Fails if directory contains any items
 *   - In recursive mode:
 *     * Utilizes PostgreSQL's CASCADE DELETE functionality
 *     * Automatically removes all subdirectories and files
 *     * Maintains referential integrity via foreign key constraints
 *   - Only affects items owned by the requesting user
 *   - Transaction safe
 *
 * Examples:
 *   -- Delete an empty directory (fails if directory contains items)
 *   SELECT directory_delete(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- directory UUID
 *     false,                                    -- non-recursive
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Delete a directory and all its contents
 *   SELECT directory_delete(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- directory UUID
 *     true,                                     -- recursive delete
 *     'user123'                                 -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION directory_delete(
    p_directory_id UUID,
    p_recursive BOOLEAN,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS VOID AS $$
BEGIN
    -- Validate directory exists and belongs to user
    IF NOT validate_directory_ownership(p_directory_id, p_user_token) THEN
        RAISE EXCEPTION 'Directory not found or access denied'
            USING ERRCODE = 'P0002'; -- no_data_found
    END IF;

    -- Check if directory has contents when non-recursive delete is requested
    IF NOT p_recursive THEN
        -- Check for subdirectories
        IF EXISTS (
            SELECT 1
            FROM directories
            WHERE parent_id = p_directory_id
                AND user_token = p_user_token
        ) THEN
            RAISE EXCEPTION 'Directory contains subdirectories. Use recursive delete to remove'
                USING ERRCODE = 'P0001'; -- raise_exception
        END IF;

        -- Check for files
        IF EXISTS (
            SELECT 1
            FROM files
            WHERE parent_id = p_directory_id
                AND user_token = p_user_token
        ) THEN
            RAISE EXCEPTION 'Directory contains files. Use recursive delete to remove'
                USING ERRCODE = 'P0001'; -- raise_exception
        END IF;
    END IF;

    -- If recursive delete is requested or directory is empty, proceed with deletion
    IF p_recursive THEN
        -- Using CASCADE will automatically delete all subdirectories and files
        -- due to the foreign key constraints with ON DELETE CASCADE
        DELETE FROM directories
        WHERE id = p_directory_id;
    ELSE
        -- Non-recursive delete (already verified directory is empty)
        DELETE FROM directories
        WHERE id = p_directory_id;
    END IF;

    -- Check if deletion was successful
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Directory deletion failed'
            USING ERRCODE = 'P0001'; -- raise_exception
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION directory_delete(UUID, BOOLEAN, TEXT) IS
'Deletes a directory and optionally its contents.
Parameters:
  - p_directory_id: UUID of the directory to delete
  - p_recursive: If true, recursively delete all contents. If false, fail if directory is not empty
  - p_user_token: User token for access control
Returns:
  - void
Raises:
  - P0002: Directory not found or access denied
  - P0001: Directory not empty (when non-recursive) or deletion failed
Notes:
  - When recursive is true, all subdirectories and files are deleted
  - When recursive is false, operation fails if directory contains any items
  - Deletion is handled by foreign key CASCADE for recursive deletes
  - Only deletes items belonging to the specified user_token';

-- Example usage:
-- Delete empty directory:
-- SELECT directory_delete('dir-uuid', false, 'user123');
-- Delete directory and all contents:
-- SELECT directory_delete('dir-uuid', true, 'user123');