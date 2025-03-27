/*
 * Function: file_details
 *
 * Retrieves detailed information about a specific file, including its metadata, storage information,
 * and associated tags. This function provides a comprehensive view of a file's properties while
 * ensuring proper access control.
 *
 * Parameters:
 *   - p_file_id (UUID): The UUID of the file to get details for
 *   - p_user_token (TEXT): The user token for access control and ownership validation
 *
 * Returns:
 *   TABLE (file_details JSON): JSON object containing:
 *     {
 *       "id": UUID,            // File's unique identifier
 *       "name": string,        // File name
 *       "created_at": timestamp,// Creation timestamp
 *       "updated_at": timestamp,// Last modification timestamp
 *       "parent_id": UUID,     // Parent directory ID (null for root)
 *       "storage_id": string,  // External storage reference ID
 *       "metadata": {          // Custom metadata object (empty object if none)
 *         // Any custom key-value pairs
 *       },
 *       "tags": {              // File tags information
 *         "names": string[],   // Array of tag names (sorted alphabetically)
 *         "ids": integer[]     // Array of tag IDs (matching names array order)
 *       }
 *     }
 *   Note: Returns NULL if file not found or access denied
 *
 * Implementation Notes:
 *   - Validates file ownership via user_token
 *   - Uses file_tags_list for tag information
 *   - Returns empty object for metadata if none exists
 *   - Returns NULL instead of raising an exception for not found/access denied
 *
 * Examples:
 *   -- Get details of a specific file
 *   SELECT * FROM file_details(
 *     '123e4567-e89b-12d3-a456-426614174000',  -- file UUID
 *     'user123'                                 -- user token
 *   );
 */

CREATE OR REPLACE FUNCTION file_details(
    p_file_id UUID,
    p_user_token TEXT DEFAULT 'public'
)
RETURNS TABLE (file_details JSON) AS $$
DECLARE
    result JSON;
    file_tags_result JSON;
BEGIN
    -- Get tags using file_tags_list function
    SELECT tags INTO file_tags_result
    FROM file_tags_list(p_file_id, p_user_token);

    -- If file_tags_list returns NULL, it means file not found or access denied
    IF file_tags_result IS NULL THEN
        RETURN QUERY SELECT NULL::JSON;
        RETURN;
    END IF;

    SELECT json_build_object(
        'id', f.id,
        'name', f.name,
        'created_at', f.created_at,
        'updated_at', f.updated_at,
        'parent_id', f.parent_id,
        'storage_id', f.storage_id,
        'metadata', COALESCE(f.metadata, '{}'::jsonb),
        'tags', file_tags_result
    ) INTO result
    FROM files f
    WHERE f.id = p_file_id
        AND f.user_token = p_user_token;

    RETURN QUERY SELECT result;
END;
$$ LANGUAGE plpgsql;

-- Add function comment
COMMENT ON FUNCTION file_details(UUID, TEXT) IS
'Retrieves detailed information about a specific file including tags.
Parameters:
  - p_file_id: UUID of the file to get details for
  - p_user_token: User token for access control
Returns:
  - file_details: JSON object with structure:
    {
      id: UUID,
      name: string,
      created_at: timestamp,
      updated_at: timestamp,
      parent_id: UUID,
      storage_id: string,
      metadata: jsonb,
      tags: {
        names: string[],
        ids: integer[]
      }
    }
Returns NULL if file not found or user_token does not match.';

-- Example usage:
-- SELECT * FROM file_details('file-uuid', 'user123');