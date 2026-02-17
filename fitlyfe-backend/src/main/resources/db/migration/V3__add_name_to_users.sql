-- Add first_name and last_name directly on the users table.
-- Previously these lived only in user_profiles; the new UserEntity maps them
-- here so that syncUser can store them without a separate profile row.
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name  VARCHAR(255);
