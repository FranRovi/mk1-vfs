/*
 * Function: directory_copy
 *
 * Recursively copies a directory and all its contents (including subdirectories and files) to a new location
 * while preserving the entire hierarchy structure. This function handles deep copying of the directory tree
 * while maintaining all metadata and creating new unique identifiers for all copied items.
 *
 * Parameters:
 *   - p_source_id (UUID): The UUID of the directory to copy
 *   - p_destination_parent_id (UUID): The UUID of the destination parent directory (NULL for root)
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   TABLE (directory_details JSON): JSON object containing the details of the newly created root directory
 *                                  (same structure as returned by directory_details)
 *
 * Error Conditions:
 *   - P0002: Source or destination directory not found or access denied
 *   - P0001: Attempt to copy directory into itself or its subdirectories
 *   - 23505: Name conflict detected in destination location
 *
 * Implementation Notes:
 *   - Performs a deep copy of the entire directory structure
 *   - Preserves all file metadata and storage IDs
 *   - Creates new UUIDs for all copied items (directories and files)
 *   - Maintains user_token based access control throughout
 *   - Uses recursive CTEs for efficient tree traversal
 *   - Implements transactional safety with automatic rollback on failure
 *
 * Examples:
 *   -- Copy a directory to the root level
 *   SELECT * FROM directory_copy(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- source directory UUID
 *     NULL,                                     -- NULL for root destination
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Copy a directory into another directory
 *   SELECT * FROM directory_copy(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- source directory UUID
 *     '987fcdeb-51k2-12d3-a456-426614174000',  -- destination parent directory UUID
 *     'user123'                                 -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION directory_copy(
    p_source_id UUID,
    p_destination_parent_id UUID,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (directory_details JSON) AS $$
DECLARE
    v_new_root_id UUID;
    v_source_name TEXT;
    result JSON;
    v_is_subdirectory BOOLEAN;
BEGIN
    -- Validate source directory exists and belongs to user
    IF NOT validate_directory_ownership(p_source_id, p_user_token) THEN
        RAISE EXCEPTION 'Source directory not found or access denied'
            USING ERRCODE = 'P0002'; -- no_data_found
    END IF;

    -- Get source directory name
    SELECT name INTO v_source_name
    FROM directories
    WHERE id = p_source_id;

    -- If destination parent specified, validate it exists and belongs to user
    IF p_destination_parent_id IS NOT NULL THEN
        IF NOT validate_directory_ownership(p_destination_parent_id, p_user_token) THEN
            RAISE EXCEPTION 'Destination parent directory not found or access denied'
                USING ERRCODE = 'P0002'; -- no_data_found
        END IF;

        -- Prevent copying directory into itself or its subdirectories
        IF validate_is_subdirectory(p_destination_parent_id, p_source_id, p_user_token) THEN
            RAISE EXCEPTION 'Cannot copy directory into itself or its subdirectories'
                USING ERRCODE = 'P0001'; -- raise_exception
        END IF;
    END IF;

    -- Check for name conflict in destination
    IF validate_directory_name_exists(v_source_name, p_destination_parent_id, p_user_token) THEN
        RAISE EXCEPTION 'Directory with name "%" already exists in destination', v_source_name
            USING ERRCODE = '23505'; -- unique_violation
    END IF;

    -- Start transaction for the entire copy operation
    BEGIN
        -- First, create the new root directory
        INSERT INTO directories (
            name,
            parent_id,
            user_token
        )
        VALUES (
            v_source_name,
            p_destination_parent_id,
            p_user_token
        )
        RETURNING id INTO v_new_root_id;

        -- Copy directory structure and files using recursive CTE
        WITH RECURSIVE dir_tree AS (
            -- Base case: direct children of source directory
            SELECT
                d.id as source_id,
                d.name,
                d.parent_id as source_parent_id,
                v_new_root_id as new_parent_id,
                1 as level
            FROM directories d
            WHERE d.parent_id = p_source_id
                AND d.user_token = p_user_token

            UNION ALL

            -- Recursive case: deeper levels
            SELECT
                d.id as source_id,
                d.name,
                d.parent_id as source_parent_id,
                nd.id as new_parent_id,
                dt.level + 1
            FROM directories d
            INNER JOIN dir_tree dt ON dt.source_id = d.parent_id
            INNER JOIN directories nd ON nd.name = dt.name
                AND nd.parent_id = dt.new_parent_id
                AND nd.user_token = p_user_token
            WHERE d.user_token = p_user_token
        )
        -- Copy directories
        INSERT INTO directories (
            name,
            parent_id,
            user_token
        )
        SELECT
            dt.name,
            dt.new_parent_id,
            p_user_token
        FROM dir_tree dt;

        -- Copy files
        WITH RECURSIVE dir_mapping AS (
            -- Base case: root directory mapping
            SELECT
                p_source_id as old_id,
                v_new_root_id as new_id

            UNION ALL

            -- Add all other directory mappings
            SELECT
                d.id as old_id,
                nd.id as new_id
            FROM directories d
            INNER JOIN dir_mapping dm ON d.parent_id = dm.old_id
            INNER JOIN directories nd ON nd.parent_id = dm.new_id
                AND nd.name = d.name
                AND nd.user_token = p_user_token
            WHERE d.user_token = p_user_token
        )
        INSERT INTO files (
            name,
            parent_id,
            storage_id,
            metadata,
            user_token
        )
        SELECT
            f.name,
            dm.new_id,
            f.storage_id,
            f.metadata,
            p_user_token
        FROM files f
        INNER JOIN dir_mapping dm ON f.parent_id = dm.old_id
        WHERE f.user_token = p_user_token;

        -- Get details of the new root directory
        SELECT d.directory_details INTO result
        FROM directory_details(v_new_root_id, p_user_token) d;

        RETURN QUERY SELECT result;
    EXCEPTION
        WHEN OTHERS THEN
            -- Cleanup on error (will be rolled back anyway, but good practice)
            DELETE FROM directories WHERE id = v_new_root_id;
            RAISE;
    END;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Name conflict occurred during copy operation'
            USING ERRCODE = '23505'; -- unique_violation
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION directory_copy(UUID, UUID, TEXT) IS
'Recursively copies a directory and all its contents to a new location.
Parameters:
  - p_source_id: UUID of the directory to copy
  - p_destination_parent_id: UUID of the destination parent directory (NULL for root)
  - p_user_token: User token for access control
Returns:
  - directory_details: JSON object with the new root directory''s details (same structure as directory_details)
Raises:
  - P0002: Source or destination directory not found or access denied
  - P0001: Cannot copy directory into itself or its subdirectories
  - 23505: Name conflict in destination location
Notes:
  - Copies entire directory structure including all subdirectories
  - Preserves file metadata and storage IDs
  - Creates new UUIDs for all copied items
  - Maintains user_token based access control';

-- Example usage:
-- Copy directory to root:
-- SELECT * FROM directory_copy('source-uuid', NULL, 'user123');
-- Copy directory into another directory:
-- SELECT * FROM directory_copy('source-uuid', 'dest-parent-uuid', 'user123');