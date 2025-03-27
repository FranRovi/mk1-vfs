/*
 * Function: directory_create
 *
 * Creates a new directory in the virtual file system with the specified name and optional parent directory.
 * This function handles the creation of directories while ensuring naming conventions, uniqueness constraints,
 * and proper access control.
 *
 * Parameters:
 *   - p_name (TEXT): Name of the new directory
 *     * Must be unique within its parent directory
 *   - p_parent_id (UUID): The UUID of the parent directory (NULL for root-level directories)
 *   - p_user_token (TEXT): The user token for access control and ownership assignment
 *
 * Returns:
 *   TABLE (directory_details JSON): JSON object containing the details of the newly created directory
 *                                  (same structure as returned by directory_details)
 *
 * Error Conditions:
 *   - P0002: Parent directory not found or access denied
 *   - 23505: Name conflict detected (directory with same name exists in parent)
 *
 * Implementation Notes:
 *   - Validates parent directory existence and ownership (if parent_id provided)
 *   - Enforces unique directory names within the same parent
 *   - Assigns ownership via user_token
 *   - Creates new UUID for the directory
 *   - Returns complete directory details via directory_details function
 *
 * Examples:
 *   -- Create a root-level directory
 *   SELECT * FROM directory_create(
 *     'Documents',           -- directory name
 *     NULL,                  -- NULL for root level
 *     'user123'             -- user token
 *   );
 *
 *   -- Create a subdirectory in an existing directory
 *   SELECT * FROM directory_create(
 *     'Projects',                                    -- directory name
 *     '123e4567-e89b-12d3-a456-426614174000',      -- parent directory UUID
 *     'user123'                                     -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION directory_create(
    p_name TEXT,
    p_parent_id UUID DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (directory_details JSON) AS $$
DECLARE
    v_new_id UUID;
    result JSON;
BEGIN
    -- Validate parent directory exists and belongs to user if parent_id is provided
    IF p_parent_id IS NOT NULL THEN
        IF NOT validate_directory_ownership(p_parent_id, p_user_token) THEN
            RAISE EXCEPTION 'Parent directory not found or access denied'
                USING ERRCODE = 'P0002'; -- no_data_found
        END IF;
    END IF;

    -- Check for duplicate name in the same parent directory
    IF validate_directory_name_exists(p_name, p_parent_id, p_user_token) THEN
        RAISE EXCEPTION 'Directory with name "%" already exists in this location', p_name
            USING ERRCODE = '23505'; -- unique_violation
    END IF;

    -- Create new directory
    INSERT INTO directories (
        name,
        parent_id,
        user_token
    )
    VALUES (
        p_name,
        p_parent_id,
        p_user_token
    )
    RETURNING id INTO v_new_id;

    -- Get full directory details using existing function
    SELECT d.directory_details INTO result
    FROM directory_details(v_new_id, p_user_token) d;

    RETURN QUERY SELECT result;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Directory with name "%" already exists in this location', p_name
            USING ERRCODE = '23505'; -- unique_violation
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION directory_create(TEXT, UUID, TEXT) IS
'Creates a new directory with the given name and optional parent.
Parameters:
  - p_name: Name of the new directory (any characters allowed)
  - p_parent_id: UUID of the parent directory (NULL for root level)
  - p_user_token: User token for access control
Returns:
  - directory_details: JSON object with the new directory''s details (same structure as directory_details)
Raises:
  - P0002: Parent directory not found or access denied
  - 23505: Directory with same name already exists in parent';

-- Example usage:
-- Create root directory:
-- SELECT * FROM directory_create('root_dir', NULL, 'user123');
-- Create subdirectory:
-- SELECT * FROM directory_create('sub_dir', 'parent-uuid', 'user123');