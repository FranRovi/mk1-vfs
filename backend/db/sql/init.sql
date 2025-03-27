CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS directories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    user_token TEXT NOT NULL,
    parent_id UUID REFERENCES directories(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (parent_id, name, user_token)
);

CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    user_token TEXT NOT NULL,
    parent_id UUID REFERENCES directories(id) ON DELETE CASCADE,
    storage_id TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (parent_id, name, user_token)
);

CREATE TABLE IF NOT EXISTS tags (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    user_token TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (name, user_token)
);

CREATE TABLE IF NOT EXISTS file_tags (
    file_id UUID REFERENCES files(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (file_id, tag_id)
);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_directories_updated_at ON directories;
CREATE TRIGGER update_directories_updated_at
    BEFORE UPDATE ON directories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_files_updated_at ON files;
CREATE TRIGGER update_files_updated_at
    BEFORE UPDATE ON files
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- Indexes
CREATE INDEX IF NOT EXISTS idx_file_tags_tag_id ON file_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_file_tags_file_id ON file_tags(file_id);

CREATE INDEX IF NOT EXISTS idx_file_metadata ON files USING GIN (metadata);

-- For faster directory tree traversal
CREATE INDEX IF NOT EXISTS idx_directories_parent_id ON directories(parent_id);

-- For user-specific queries (if you frequently filter by user)
CREATE INDEX IF NOT EXISTS idx_directories_user_token ON directories(user_token);
CREATE INDEX IF NOT EXISTS idx_files_user_token ON files(user_token);

-- For name searches (if you do partial name matches)
CREATE INDEX IF NOT EXISTS idx_directories_name ON directories(name);
CREATE INDEX IF NOT EXISTS idx_files_name ON files(name);
