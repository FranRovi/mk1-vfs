/*
 * Mock Data Population Script
 *
 * This script populates the database with mock data for testing purposes.
 * It creates a realistic directory structure with files and tags.
 */

-- Start fresh - Clear existing data
DELETE FROM file_tags;
DELETE FROM files;
DELETE FROM directories;
DELETE FROM tags;

DO $$
DECLARE
    user1 text := 'public';
    user2 text := 'user456';
BEGIN

-- Create root level directories for user1
WITH root_dirs AS (
    INSERT INTO directories (name, parent_id, user_token)
    VALUES
        ('Documents', NULL, user1),
        ('Pictures', NULL, user1),
        ('Projects', NULL, user1)
    RETURNING id, name
),
-- Create subdirectories in Documents
doc_subdirs AS (
    INSERT INTO directories (name, parent_id, user_token)
    SELECT
        subdir.name,
        rd.id,
        user1
    FROM root_dirs rd
    CROSS JOIN (
        VALUES
            ('Work'),
            ('Personal'),
            ('Archive')
    ) AS subdir(name)
    WHERE rd.name = 'Documents'
    RETURNING id, name, parent_id
),
-- Create subdirectories in Projects
proj_subdirs AS (
    INSERT INTO directories (name, parent_id, user_token)
    SELECT
        subdir.name,
        rd.id,
        user1
    FROM root_dirs rd
    CROSS JOIN (
        VALUES
            ('Frontend'),
            ('Backend'),
            ('Documentation')
    ) AS subdir(name)
    WHERE rd.name = 'Projects'
    RETURNING id, name, parent_id
),
-- Create some tags
tags_insert AS (
    INSERT INTO tags (name, user_token)
    VALUES
        ('work', user1),
        ('personal', user1),
        ('important', user1),
        ('archived', user1),
        ('draft', user1),
        ('final', user1)
    RETURNING id, name
),
-- Create files in various directories
files_insert AS (
    -- Files in Documents/Work
    INSERT INTO files (name, parent_id, storage_id, metadata, user_token)
    SELECT
        file.name,
        ds.id,
        'store_' || gen_random_uuid(),
        file.metadata,
        user1
    FROM doc_subdirs ds
    CROSS JOIN (
        VALUES
            ('report_2024.pdf', '{"type": "pdf", "size": 1048576, "status": "final"}'::jsonb),
            ('meeting_notes.txt', '{"type": "text", "size": 2048, "status": "draft"}'::jsonb),
            ('presentation.pptx', '{"type": "powerpoint", "size": 5242880, "status": "final"}'::jsonb)
    ) AS file(name, metadata)
    WHERE ds.name = 'Work'
    UNION ALL
    -- Files in Documents/Personal
    SELECT
        file.name,
        ds.id,
        'store_' || gen_random_uuid(),
        file.metadata,
        user1
    FROM doc_subdirs ds
    CROSS JOIN (
        VALUES
            ('budget_2024.xlsx', '{"type": "excel", "size": 102400, "status": "draft"}'::jsonb),
            ('recipes.docx', '{"type": "word", "size": 51200, "status": "final"}'::jsonb)
    ) AS file(name, metadata)
    WHERE ds.name = 'Personal'
    UNION ALL
    -- Files in Projects/Frontend
    SELECT
        file.name,
        ps.id,
        'store_' || gen_random_uuid(),
        file.metadata,
        user1
    FROM proj_subdirs ps
    CROSS JOIN (
        VALUES
            ('index.html', '{"type": "html", "size": 4096, "status": "final"}'::jsonb),
            ('styles.css', '{"type": "css", "size": 2048, "status": "draft"}'::jsonb),
            ('app.js', '{"type": "javascript", "size": 8192, "status": "draft"}'::jsonb)
    ) AS file(name, metadata)
    WHERE ps.name = 'Frontend'
    UNION ALL
    -- Files in Projects/Backend
    SELECT
        file.name,
        ps.id,
        'store_' || gen_random_uuid(),
        file.metadata,
        user1
    FROM proj_subdirs ps
    CROSS JOIN (
        VALUES
            ('server.py', '{"type": "python", "size": 16384, "status": "final"}'::jsonb),
            ('database.sql', '{"type": "sql", "size": 32768, "status": "draft"}'::jsonb)
    ) AS file(name, metadata)
    WHERE ps.name = 'Backend'
    RETURNING id, name
)
-- Create file-tag associations
INSERT INTO file_tags (file_id, tag_id)
SELECT
    f.id,
    t.id
FROM files_insert f
CROSS JOIN tags_insert t
WHERE
    (f.name LIKE '%final%' AND t.name = 'final') OR
    (f.name LIKE '%draft%' AND t.name = 'draft') OR
    (f.name LIKE 'report%' AND t.name = 'work') OR
    (f.name LIKE 'budget%' AND t.name = 'personal') OR
    (f.name LIKE 'server%' AND t.name = 'important');

-- Create a separate structure for user2 to test isolation
WITH root_dirs AS (
    INSERT INTO directories (name, parent_id, user_token)
    VALUES
        ('Downloads', NULL, user2),
        ('Music', NULL, user2)
    RETURNING id, name
),
-- Create some tags for user2
tags_insert AS (
    INSERT INTO tags (name, user_token)
    VALUES
        ('music', user2),
        ('downloads', user2)
    RETURNING id, name
),
-- Create files for user2
files_insert AS (
    INSERT INTO files (name, parent_id, storage_id, metadata, user_token)
    SELECT
        file.name,
        rd.id,
        'store_' || gen_random_uuid(),
        file.metadata,
        user2
    FROM root_dirs rd
    CROSS JOIN (
        VALUES
            ('song.mp3', '{"type": "audio", "size": 4194304, "artist": "Test Artist"}'::jsonb),
            ('playlist.m3u', '{"type": "playlist", "size": 1024}'::jsonb)
    ) AS file(name, metadata)
    WHERE rd.name = 'Music'
    RETURNING id, name
)
-- Create file-tag associations for user2
INSERT INTO file_tags (file_id, tag_id)
SELECT
    f.id,
    t.id
FROM files_insert f
CROSS JOIN tags_insert t
WHERE t.name = 'music';

END $$;