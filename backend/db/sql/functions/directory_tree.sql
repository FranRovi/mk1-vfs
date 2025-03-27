CREATE OR REPLACE FUNCTION directory_tree(
    p_parent_id UUID DEFAULT NULL,
    p_user_token TEXT DEFAULT 'public',
    p_max_depth INTEGER DEFAULT 3
) RETURNS TABLE (tree JSON) AS $$
WITH RECURSIVE
-- First, get the directory hierarchy recursively
directory_hierarchy AS (
    -- Base case: starting level directories
    SELECT
        (json_array_elements(directory_listd(p_parent_id, p_user_token))->>'id')::UUID as id,
        (json_array_elements(directory_listd(p_parent_id, p_user_token))->>'name')::TEXT as name,
        (json_array_elements(directory_listd(p_parent_id, p_user_token))->>'created_at')::TIMESTAMPTZ as created_at,
        1 as depth

    UNION ALL

    -- Recursive case: child directories
    SELECT
        (json_array_elements(directory_listd(dh.id, p_user_token))->>'id')::UUID as id,
        (json_array_elements(directory_listd(dh.id, p_user_token))->>'name')::TEXT as name,
        (json_array_elements(directory_listd(dh.id, p_user_token))->>'created_at')::TIMESTAMPTZ as created_at,
        dh.depth + 1
    FROM directory_hierarchy dh
    WHERE dh.depth < p_max_depth
),

-- Build the tree structure bottom-up
directory_tree_builder AS (
    SELECT
        dh.id,
        dh.name,
        dh.created_at,
        dh.depth,
        json_build_object(
            'id', dh.id,
            'name', dh.name,
            'created_at', dh.created_at,
            'type', 'directory',
            'children', COALESCE(
                (
                    WITH files AS (
                        -- Get files in this directory
                        SELECT json_array_elements(directory_listf(dh.id, p_user_token)) as file
                    ),
                    child_dirs AS (
                        -- Get immediate child directories
                        SELECT json_array_elements(directory_listd(dh.id, p_user_token)) as dir
                    )
                    SELECT json_agg(item ORDER BY (item->>'name'))
                    FROM (
                        -- Combine files and child directories
                        SELECT json_build_object(
                            'id', (file->>'id')::UUID,
                            'name', file->>'name',
                            'created_at', (file->>'created_at')::TIMESTAMPTZ,
                            'type', 'file'
                        ) as item
                        FROM files

                        UNION ALL

                        SELECT json_build_object(
                            'id', (dir->>'id')::UUID,
                            'name', dir->>'name',
                            'created_at', (dir->>'created_at')::TIMESTAMPTZ,
                            'type', 'directory',
                            'children', '[]'::JSON
                        ) as item
                        FROM child_dirs
                    ) items
                ),
                '[]'::JSON
            )
        ) as tree_node
    FROM directory_hierarchy dh
)

-- Final assembly with proper nesting
SELECT
    COALESCE(
        json_agg(
            dtb.tree_node ORDER BY dtb.name
        ),
        '[]'::JSON
    ) as tree
FROM directory_tree_builder dtb
WHERE dtb.depth = 1;

$$ LANGUAGE SQL;

COMMENT ON FUNCTION directory_tree(UUID, TEXT, INTEGER) IS
'Builds a hierarchical JSON tree of directories and files using directory_listd and directory_listf helpers.
Parameters:
  - p_parent_id: Starting directory UUID (NULL for root)
  - p_user_token: Access control token
  - p_max_depth: Maximum directory depth to traverse
Returns a JSON tree structure containing directories and their contents.';