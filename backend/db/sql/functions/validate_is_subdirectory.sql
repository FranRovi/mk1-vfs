/*
 * Function: validate_is_subdirectory
 *
 * Checks if a directory is a subdirectory (at any depth) of another directory.
 * This function uses recursive traversal to check the entire directory tree.
 *
 * Parameters:
 *   - p_potential_parent_id (UUID): The UUID of the potential parent directory
 *   - p_potential_child_id (UUID): The UUID of the potential child directory
 *   - p_user_token (TEXT): The user token for access control
 *
 * Returns:
 *   BOOLEAN:
 *     - TRUE if potential_child is a subdirectory of potential_parent
 *     - FALSE otherwise
 *
 * Implementation Notes:
 *   - Uses recursive CTE for efficient tree traversal
 *   - Only considers directories owned by the specified user
 *   - Returns FALSE if either directory doesn't exist
 *   - Handles direct and indirect child relationships
 *
 * Examples:
 *   -- Check if directory B is inside directory A
 *   SELECT validate_is_subdirectory(
 *     'directory-a-uuid',  -- potential parent
 *     'directory-b-uuid',  -- potential child
 *     'user123'           -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION validate_is_subdirectory(
    p_potential_parent_id UUID,
    p_potential_child_id UUID,
    p_user_token TEXT DEFAULT 'public'
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        WITH RECURSIVE subdirs AS (
            -- Base case: direct children
            SELECT id, parent_id
            FROM directories
            WHERE parent_id = p_potential_child_id
                AND user_token = p_user_token

            UNION ALL

            -- Recursive case: all descendants
            SELECT d.id, d.parent_id
            FROM directories d
            INNER JOIN subdirs s ON d.parent_id = s.id
            WHERE d.user_token = p_user_token
        )
        SELECT 1 FROM subdirs WHERE id = p_potential_parent_id
    );
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION validate_is_subdirectory(UUID, UUID, TEXT) IS
'Checks if a directory is a subdirectory of another directory.
Parameters:
  - p_potential_parent_id: UUID of the potential parent directory
  - p_potential_child_id: UUID of the potential child directory
  - p_user_token: User token for access control
Returns:
  - boolean: TRUE if child is a subdirectory of parent, FALSE otherwise
Notes:
  - Uses recursive traversal to check entire directory tree
  - Only considers directories owned by the user
  - Returns FALSE if either directory does not exist';

-- Example usage:
-- SELECT validate_is_subdirectory('parent-uuid', 'child-uuid', 'user123');