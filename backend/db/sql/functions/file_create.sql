/*
 * Function: create_file
 *
 * Creates a new file in the virtual file system with the specified name and parent directory.
 * This function handles the creation of files while ensuring naming conventions, uniqueness constraints,
 * and proper access control.
 *
 * Parameters:
 *   - p_name (TEXT): Name of the new file
 *     * Must be unique within its parent directory
 *   - p_parent_id (UUID): The UUID of the parent directory (required)
 *   - p_user_token (TEXT): The user token for access control and ownership assignment
 *   - p_storage_id (TEXT): External storage identifier for the file content
 *   - p_metadata (JSONB): Optional metadata associated with the file (defaults to empty JSON)
 *
 * Returns:
 *   TABLE (file_details JSON): JSON object containing the details of the newly created file
 *                             (same structure as returned by file_details)
 *
 * Error Conditions:
 *   - P0002: Parent directory not found or access denied
 *   - 23505: Name conflict detected (file with same name exists in parent)
 *
 * Implementation Notes:
 *   - Validates parent directory existence and ownership
 *   - Enforces unique file names within the same parent directory
 *   - Assigns ownership via user_token
 *   - Creates new UUID for the file
 *   - Returns complete file details via file_details function
 *
 * Example Usage:
 *   SELECT * FROM create_file(
 *     'document.txt',
 *     '123e4567-e89b-12d3-a456-426614174000'::UUID,
 *     'user_123',
 *     'store_456',
 *     '{"size": 1024, "mime_type": "text/plain"}'
 *   );
 *
 *   Returns:
 *   {
 *     "id": "987fcdeb-51a2-43f7-9abc-def012345678",
 *     "name": "document.txt",
 *     "parent_id": "123e4567-e89b-12d3-a456-426614174000",
 *     "storage_id": "store_456",
 *     "created_at": "2024-03-20T10:30:00Z",
 *     "updated_at": "2024-03-20T10:30:00Z",
 *     "metadata": {
 *       "size": 1024,
 *       "mime_type": "text/plain"
 *     }
 *   }
 */

CREATE OR REPLACE FUNCTION file_create(
    p_name TEXT,
    p_parent_id UUID,
    p_user_token TEXT,
    p_storage_id TEXT,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS TABLE (file_details JSON) AS $$
DECLARE
    v_new_id UUID;
    result JSON;
BEGIN
    -- Validate parent directory exists and belongs to user (required for files)
    IF NOT validate_directory_ownership(p_parent_id, p_user_token) THEN
        RAISE EXCEPTION 'Parent directory not found or access denied'
            USING ERRCODE = 'P0002'; -- no_data_found
    END IF;

    -- Check for duplicate name in the same parent directory
    IF EXISTS (
        SELECT 1
        FROM files
        WHERE name = p_name
            AND parent_id = p_parent_id
            AND user_token = p_user_token
    ) THEN
        RAISE EXCEPTION 'File with name "%" already exists in this location', p_name
            USING ERRCODE = '23505'; -- unique_violation
    END IF;

    -- Create new file
    INSERT INTO files (
        name,
        parent_id,
        user_token,
        storage_id,
        metadata
    )
    VALUES (
        p_name,
        p_parent_id,
        p_user_token,
        p_storage_id,
        COALESCE(p_metadata, '{}')
    )
    RETURNING id INTO v_new_id;

    -- Get full file details using existing function
    SELECT f.file_details INTO result
    FROM file_details(v_new_id, p_user_token) f;

    RETURN QUERY SELECT result;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'File with name "%" already exists in this location', p_name
            USING ERRCODE = '23505'; -- unique_violation
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION file_create(TEXT, UUID, TEXT, TEXT, JSONB) IS
'Creates a new file with the given name in the specified parent directory.
Parameters:
  - p_name: Name of the new file (any characters allowed)
  - p_parent_id: UUID of the parent directory (required)
  - p_user_token: User token for access control
  - p_storage_id: External storage identifier for the file content
  - p_metadata: Optional JSON metadata for the file
Returns:
  - file_details: JSON object with the new file''s details (same structure as file_details)
Raises:
  - P0002: Parent directory not found or access denied
  - 23505: File with same name already exists in parent';

-- Example usage:
-- SELECT * FROM create_file('example.txt', 'parent-uuid', 'user123', 'storage123', '{"size": 1024}');