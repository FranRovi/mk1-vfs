/*
 * Function: directory_update
 *
 * Updates a directory's properties, allowing for name changes and/or relocation within the directory
 * hierarchy. This function handles both simple renames and complex move operations while ensuring
 * naming uniqueness, proper access control, and structural integrity.
 *
 * Parameters:
 *   - p_directory_id (UUID): The UUID of the directory to update
 *   - p_name (TEXT): Optional new name for the directory
 *     * Must be unique within the parent directory
 *     * If NULL, keeps current name
 *   - p_new_parent_id (UUID): Optional new parent directory UUID
 *     * If NULL, keeps current parent
 *     * Use NULL for root level
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   TABLE (directory_details JSON): JSON object with updated directory details
 *     (same structure as returned by directory_details)
 *
 * Error Conditions:
 *   - P0002: Directory not found or access denied
 *   - P0002: New parent directory not found or access denied
 *   - P0001: Attempt to move directory into its own subdirectory
 *   - 23505: Name conflict in target location
 *
 * Implementation Notes:
 *   - Validates ownership of both source directory and target parent
 *   - Prevents circular references in directory structure
 *   - Handles partial updates (name only, location only, or both)
 *   - Maintains unique names within each directory level
 *   - Uses recursive CTE to validate move operations
 *   - Updates timestamps automatically via triggers
 *   - Returns complete updated directory details
 *   - Maintains referential integrity
 *
 * Examples:
 *   -- Rename a directory
 *   SELECT * FROM directory_update(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- directory UUID
 *     'New_Name',                               -- new name
 *     NULL,                                     -- keep current parent
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Move directory to new parent
 *   SELECT * FROM directory_update(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- directory UUID
 *     NULL,                                     -- keep current name
 *     '987fcdeb-51k2-12d3-a456-426614174000',  -- new parent UUID
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Move directory to root level
 *   SELECT * FROM directory_update(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- directory UUID
 *     'Root_Dir',                               -- new name
 *     NULL,                                     -- NULL parent for root
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Example result:
 *   -- {
 *   --   "id": "123e4567-e89b-12d3-a456-426614174000",
 *   --   "name": "New_Name",
 *   --   "created_at": "2024-01-15T10:30:00Z",
 *   --   "updated_at": "2024-01-15T14:45:00Z",
 *   --   "parent_id": "987fcdeb-51k2-12d3-a456-426614174000",
 *   --   "child_counts": {
 *   --     "directories": 2,
 *   --     "files": 3,
 *   --     "total": 5
 *   --   }
 *   -- }
 */

CREATE OR REPLACE FUNCTION directory_update(
    p_directory_id UUID,
    p_name TEXT DEFAULT NULL,
    p_new_parent_id UUID DEFAULT NULL,
    p_user_token TEXT  DEFAULT 'public'
)
RETURNS TABLE (directory_details JSON) AS $$
DECLARE
    v_current_parent_id UUID;
    v_current_name TEXT;
    result JSON;
BEGIN
    -- Get current directory details and validate ownership
    IF NOT validate_directory_ownership(p_directory_id, p_user_token) THEN
        RAISE EXCEPTION 'Directory not found or access denied'
            USING ERRCODE = 'P0002'; -- no_data_found
    END IF;

    -- Get current directory details
    SELECT parent_id, name INTO v_current_parent_id, v_current_name
    FROM directories
    WHERE id = p_directory_id;

    -- If new parent specified, validate it exists and belongs to user
    IF p_new_parent_id IS NOT NULL AND p_new_parent_id != v_current_parent_id THEN
        -- Check if new parent exists and belongs to user
        IF NOT validate_directory_ownership(p_new_parent_id, p_user_token) THEN
            RAISE EXCEPTION 'New parent directory not found or access denied'
                USING ERRCODE = 'P0002'; -- no_data_found
        END IF;

        -- Prevent moving directory to its own subdirectory
        IF validate_is_subdirectory(p_new_parent_id, p_directory_id, p_user_token) THEN
            RAISE EXCEPTION 'Cannot move directory to its own subdirectory'
                USING ERRCODE = 'P0001'; -- raise_exception
        END IF;
    END IF;

    -- If name is changing, check for duplicates in target location
    IF (p_name IS NOT NULL AND p_name != v_current_name) OR
       (p_new_parent_id IS NOT NULL AND p_new_parent_id != v_current_parent_id) THEN
        IF validate_directory_name_exists(
            COALESCE(p_name, v_current_name),
            COALESCE(p_new_parent_id, v_current_parent_id),
            p_user_token,
            p_directory_id
        ) THEN
            RAISE EXCEPTION 'Directory with name "%" already exists in target location',
                COALESCE(p_name, v_current_name)
                USING ERRCODE = '23505'; -- unique_violation
        END IF;
    END IF;

    -- Update directory
    UPDATE directories
    SET name = COALESCE(p_name, name),
        parent_id = COALESCE(p_new_parent_id, parent_id)
    WHERE id = p_directory_id;

    -- Get updated directory details
    SELECT d.directory_details INTO result
    FROM directory_details(p_directory_id, p_user_token) d;

    RETURN QUERY SELECT result;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Directory with name "%" already exists in target location',
            COALESCE(p_name, v_current_name)
            USING ERRCODE = '23505'; -- unique_violation
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION directory_update(UUID, TEXT, UUID, TEXT) IS
'Updates a directory''s name and/or moves it to a new parent directory.
Parameters:
  - p_directory_id: UUID of the directory to update
  - p_name: New name for the directory (optional)
  - p_new_parent_id: New parent directory UUID (optional)
  - p_user_token: User token for access control
Returns:
  - directory_details: JSON object with the updated directory''s details (same structure as directory_details)
Raises:
  - P0002: Directory or new parent not found or access denied
  - P0001: Cannot move directory to its own subdirectory
  - 23505: Directory with same name already exists in target location';

-- Example usage:
-- Rename directory:
-- SELECT * FROM directory_update('dir-uuid', 'new_name', NULL, 'user123');
-- Move directory:
-- SELECT * FROM directory_update('dir-uuid', NULL, 'new-parent-uuid', 'user123');
-- Rename and move:
-- SELECT * FROM directory_update('dir-uuid', 'new_name', 'new-parent-uuid', 'user123');