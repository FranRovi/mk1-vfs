/*
 * Function: file_delete
 *
 * Deletes a file from the virtual file system along with its associated metadata and tag relationships.
 * This function ensures proper access control and maintains data consistency by handling both the file
 * record and its related data in an atomic operation.
 *
 * Parameters:
 *   - p_file_id (UUID): The UUID of the file to delete
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   VOID
 *
 * Error Conditions:
 *   - P0002: File not found or access denied
 *   - P0001: Deletion operation failed
 *
 * Implementation Notes:
 *   - Validates file existence and ownership before deletion
 *   - Automatically removes associated file-tag relationships via CASCADE
 *   - Does not delete the tags themselves, only the associations
 *   - Only affects files owned by the requesting user
 *   - Transaction safe (atomic operation)
 *   - Uses foreign key constraints to maintain referential integrity
 *
 * Examples:
 *   -- Delete a file and its associated metadata
 *   SELECT file_delete(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- file UUID
 *     'user123'                                 -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION file_delete(
    p_file_id UUID,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS VOID AS $$
BEGIN
    -- Validate file exists and belongs to user
    IF NOT validate_file_ownership(p_file_id, p_user_token) THEN
        RAISE EXCEPTION 'File not found or access denied'
            USING ERRCODE = 'P0002'; -- no_data_found
    END IF;

    -- Delete the file (associated file_tags will be deleted via CASCADE)
    DELETE FROM files
    WHERE id = p_file_id;

    -- Check if deletion was successful
    IF NOT FOUND THEN
        RAISE EXCEPTION 'File deletion failed'
            USING ERRCODE = 'P0001'; -- raise_exception
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION file_delete(UUID, TEXT) IS
'Deletes a file and its associated tags.
Parameters:
  - p_file_id: UUID of the file to delete
  - p_user_token: User token for access control
Returns:
  - void
Raises:
  - P0002: File not found or access denied
  - P0001: Deletion failed
Notes:
  - Associated file_tags are automatically deleted via CASCADE
  - Only deletes files owned by the user
  - Tags themselves are not deleted, only the file-tag associations
  - Operation is atomic (transaction)';

-- Example usage:
-- SELECT file_delete('file-uuid', 'user123');