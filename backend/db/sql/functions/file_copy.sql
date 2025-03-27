/*
 * Function: file_copy
 *
 * Creates a copy of a file along with all its associated metadata and tags in a new location.
 * This function performs an atomic copy operation that ensures data consistency and maintains
 * all file properties while creating a new unique identifier for the copied file.
 *
 * Parameters:
 *   - p_source_id (UUID): The UUID of the file to copy
 *   - p_destination_parent_id (UUID): The UUID of the destination parent directory (NULL for root)
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   TABLE (file_details JSON): JSON object containing the details of the newly created file
 *                             (same structure as returned by file_details)
 *
 * Error Conditions:
 *   - P0002: Source file or destination directory not found or access denied
 *   - 23505: Name conflict detected (file with same name exists in destination)
 *
 * Implementation Notes:
 *   - Performs a complete copy of the file entry including:
 *     * All file metadata
 *     * All associated tags
 *     * Storage ID reference (points to same underlying storage)
 *   - Creates a new UUID for the copied file
 *   - Maintains user_token based access control
 *   - Implements transactional safety with automatic rollback on failure
 *   - Only copies files owned by the requesting user
 *
 * Examples:
 *   -- Copy a file to the root level
 *   SELECT * FROM file_copy(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- source file UUID
 *     NULL,                                     -- NULL for root destination
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Copy a file into another directory
 *   SELECT * FROM file_copy(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- source file UUID
 *     '987fcdeb-51k2-12d3-a456-426614174000',  -- destination parent directory UUID
 *     'user123'                                 -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION file_copy(
    p_source_id UUID,
    p_destination_parent_id UUID,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (file_details JSON) AS $$
DECLARE
    v_new_id UUID;
    v_source_name TEXT;
    result JSON;
BEGIN
    -- Validate source file ownership
    IF NOT validate_file_ownership(p_source_id, p_user_token) THEN
        RAISE EXCEPTION 'Source file not found or access denied'
            USING ERRCODE = 'P0002';
    END IF;

    -- Get source file name
    SELECT name INTO v_source_name
    FROM files
    WHERE id = p_source_id;

    -- If destination parent specified, validate ownership
    IF p_destination_parent_id IS NOT NULL THEN
        IF NOT validate_directory_ownership(p_destination_parent_id, p_user_token) THEN
            RAISE EXCEPTION 'Destination parent directory not found or access denied'
                USING ERRCODE = 'P0002';
        END IF;
    END IF;

    -- Check for name conflict in destination
    IF EXISTS (
        SELECT 1
        FROM files
        WHERE name = v_source_name
            AND COALESCE(parent_id, UUID_NIL()) = COALESCE(p_destination_parent_id, UUID_NIL())
            AND user_token = p_user_token
    ) THEN
        RAISE EXCEPTION 'File with name "%" already exists in destination', v_source_name
            USING ERRCODE = '23505';
    END IF;

    -- Start transaction for the entire copy operation
    BEGIN
        -- Copy the file with its metadata
        INSERT INTO files (
            name,
            parent_id,
            storage_id,
            metadata,
            user_token
        )
        SELECT
            name,
            p_destination_parent_id,
            storage_id,
            metadata,
            p_user_token
        FROM files
        WHERE id = p_source_id
            AND user_token = p_user_token
        RETURNING id INTO v_new_id;

        -- Copy tags
        INSERT INTO file_tags (file_id, tag_id)
        SELECT
            v_new_id,
            ft.tag_id
        FROM file_tags ft
        INNER JOIN files f ON f.id = ft.file_id
        WHERE f.id = p_source_id
            AND f.user_token = p_user_token;

        -- Get details of the new file
        SELECT f.file_details INTO result
        FROM file_details(v_new_id, p_user_token) f;

        RETURN QUERY SELECT result;
    EXCEPTION
        WHEN OTHERS THEN
            -- Cleanup on error (will be rolled back anyway, but good practice)
            DELETE FROM files WHERE id = v_new_id;
            RAISE;
    END;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'File with name "%" already exists in destination', v_source_name
            USING ERRCODE = '23505'; -- unique_violation
END;
$$ LANGUAGE plpgsql;

-- Update function comment
COMMENT ON FUNCTION file_copy(UUID, UUID, TEXT) IS
'Creates a copy of a file with its metadata and tags in a new location.
Parameters:
  - p_source_id: UUID of the file to copy
  - p_destination_parent_id: UUID of the destination parent directory (NULL for root)
  - p_user_token: User token for access control
Returns:
  - file_details: JSON object with the new file''s details (same structure as file_details)
Raises:
  - P0002: Source file or destination directory not found or access denied
  - 23505: File with same name already exists in destination
Notes:
  - Copies all file metadata and tags
  - Creates new UUID for the copied file
  - Maintains same storage_id reference
  - All operations are atomic (transaction)
  - Only copies files owned by the user';

-- Example usage:
-- SELECT * FROM file_copy('source-uuid', NULL, 'user123');
-- SELECT * FROM file_copy('source-uuid', 'dest-parent-uuid', 'user123');