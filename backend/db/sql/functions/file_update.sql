/*
 * Function: file_update
 *
 * Updates a file's properties, allowing for name changes, relocation, and metadata updates.
 * This function handles various types of updates while ensuring naming uniqueness, proper
 * access control, and data consistency.
 *
 * Parameters:
 *   - p_file_id (UUID): The UUID of the file to update
 *   - p_name (TEXT): Optional new name for the file
 *     * Must be unique within the parent directory
 *     * If NULL, keeps current name
 *   - p_new_parent_id (UUID): Optional new parent directory UUID
 *     * If NULL, keeps current parent
 *     * Use NULL for root level
 *   - p_metadata (JSONB): Optional new metadata object
 *     * If NULL, keeps current metadata
 *     * If provided, replaces entire metadata object (not merged)
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   TABLE (file_details JSON): JSON object containing the updated file details
 *     (same structure as returned by file_details)
 *
 * Error Conditions:
 *   - P0002: File not found or access denied
 *   - P0002: New parent directory not found or access denied
 *   - 23505: Name conflict in target location
 *
 * Implementation Notes:
 *   - Validates ownership of both source file and target parent directory
 *   - Handles partial updates (name only, location only, metadata only, or combinations)
 *   - Maintains unique file names within each directory level
 *   - Updates timestamps automatically via triggers
 *   - Returns complete updated file details including tags
 *   - All operations are atomic (transaction-based)
 *   - For tag management, use the separate manage_file_tags function
 *   - Metadata updates replace the entire object (not merged with existing)
 *
 * Examples:
 *   -- Update file name only
 *   SELECT * FROM file_update(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- file UUID
 *     'new_report.pdf',                         -- new name
 *     NULL,                                     -- keep current parent
 *     NULL,                                     -- keep current metadata
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Move file to new directory
 *   SELECT * FROM file_update(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- file UUID
 *     NULL,                                     -- keep current name
 *     '987fcdeb-51k2-12d3-a456-426614174000',  -- new parent UUID
 *     NULL,                                     -- keep current metadata
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Update file metadata
 *   SELECT * FROM file_update(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- file UUID
 *     NULL,                                     -- keep current name
 *     NULL,                                     -- keep current parent
 *     '{"version": "2.0", "status": "final"}'::jsonb,  -- new metadata
 *     'user123'                                 -- user token
 *   );
 *
 *   -- Example result:
 *   -- {
 *   --   "id": "123e4567-e89b-12d3-a456-426614174000",
 *   --   "name": "new_report.pdf",
 *   --   "created_at": "2024-01-15T10:30:00Z",
 *   --   "updated_at": "2024-01-15T14:45:00Z",
 *   --   "parent_id": "987fcdeb-51k2-12d3-a456-426614174000",
 *   --   "storage_id": "store123",
 *   --   "metadata": {
 *   --     "version": "2.0",
 *   --     "status": "final"
 *   --   },
 *   --   "tags": {
 *   --     "names": ["document", "pdf"],
 *   --     "ids": [1, 2]
 *   --   }
 *   -- }
 */

CREATE OR REPLACE FUNCTION file_update(
    p_file_id UUID,
    p_name TEXT DEFAULT NULL,
    p_new_parent_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (file_details JSON) AS $$
DECLARE
    v_current_parent_id UUID;
    v_current_name TEXT;
    result JSON;
BEGIN
    -- Get current file details and validate ownership
    IF NOT validate_file_ownership(p_file_id, p_user_token) THEN
        RAISE EXCEPTION 'File not found or access denied'
            USING ERRCODE = 'P0002'; -- no_data_found
    END IF;

    -- Get current file details
    SELECT parent_id, name INTO v_current_parent_id, v_current_name
    FROM files
    WHERE id = p_file_id;

    -- If new parent specified, validate it exists and belongs to user
    IF p_new_parent_id IS NOT NULL AND p_new_parent_id != v_current_parent_id THEN
        IF NOT validate_directory_ownership(p_new_parent_id, p_user_token) THEN
            RAISE EXCEPTION 'New parent directory not found or access denied'
                USING ERRCODE = 'P0002'; -- no_data_found
        END IF;
    END IF;

    -- If name is changing, check for duplicates in target location
    IF (p_name IS NOT NULL AND p_name != v_current_name) OR
       (p_new_parent_id IS NOT NULL AND p_new_parent_id != v_current_parent_id) THEN
        IF validate_file_name_exists(
            COALESCE(p_name, v_current_name),
            COALESCE(p_new_parent_id, v_current_parent_id),
            p_user_token,
            p_file_id
        ) THEN
            RAISE EXCEPTION 'File with name "%" already exists in target location',
                COALESCE(p_name, v_current_name)
                USING ERRCODE = '23505'; -- unique_violation
        END IF;
    END IF;

    -- Start transaction for the entire update operation
    BEGIN
        -- Update file basic details
        UPDATE files
        SET name = COALESCE(p_name, name),
            parent_id = COALESCE(p_new_parent_id, parent_id),
            metadata = COALESCE(p_metadata, metadata)
        WHERE id = p_file_id;

        -- Get updated file details
        SELECT f.file_details INTO result
        FROM file_details(p_file_id, p_user_token) f;

        RETURN QUERY SELECT result;
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback will happen automatically
            RAISE;
    END;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'File with name "%" already exists in target location',
            COALESCE(p_name, v_current_name)
            USING ERRCODE = '23505'; -- unique_violation
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION file_update(UUID, TEXT, UUID, JSONB, TEXT) IS
'Updates a file''s basic details including name, location, and metadata.
Parameters:
  - p_file_id: UUID of the file to update
  - p_name: New name for the file (optional)
  - p_new_parent_id: New parent directory UUID (optional)
  - p_metadata: New metadata JSONB object (optional)
  - p_user_token: User token for access control
Returns:
  - file_details: JSON object with the updated file''s details (same structure as file_details)
Raises:
  - P0002: File or new parent directory not found or access denied
  - 23505: File with same name already exists in target location
Notes:
  - Any NULL parameter means "keep existing value"
  - Metadata is replaced entirely if provided (not merged)
  - All operations are atomic (transaction)
  - For tag management, use the manage_file_tags function instead';

-- Example usage:
-- Update name only:
-- SELECT * FROM file_update('file-uuid', 'new_name', NULL, NULL, 'user123');
-- Update location only:
-- SELECT * FROM file_update('file-uuid', NULL, 'new-parent-uuid', NULL, 'user123');
-- Update metadata only:
-- SELECT * FROM file_update('file-uuid', NULL, NULL, '{"key": "value"}'::jsonb, 'user123');
-- Update multiple attributes:
-- SELECT * FROM file_update('file-uuid', 'new_name', 'new-parent-uuid', '{"key": "value"}'::jsonb, 'user123');