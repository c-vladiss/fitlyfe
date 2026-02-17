-- Migrate from Keycloak auth to Supabase auth.
-- Both column names are dropped defensively since keycloak_id was in V1 SQL
-- but keycloak_sub was used by JPA (ddl-auto:update) — one or both may exist.

ALTER TABLE users DROP COLUMN IF EXISTS keycloak_id;
ALTER TABLE users DROP COLUMN IF EXISTS keycloak_sub;

ALTER TABLE users ADD COLUMN IF NOT EXISTS supabase_id UUID;
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE;

-- Clean up any orphaned rows that have no identity (shouldn't exist in dev)
DELETE FROM users WHERE supabase_id IS NULL;

ALTER TABLE users ALTER COLUMN supabase_id SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS users_supabase_id_idx ON users(supabase_id);
