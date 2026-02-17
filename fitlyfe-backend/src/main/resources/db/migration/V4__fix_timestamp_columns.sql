-- Fix timestamp columns that were incorrectly created as bigint by Hibernate
-- Only runs the ALTER if the column is actually bigint type

DO $$
BEGIN
    -- Fix created_at if it's bigint
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'created_at'
        AND data_type = 'bigint'
    ) THEN
        ALTER TABLE users
            ALTER COLUMN created_at TYPE TIMESTAMP
            USING to_timestamp(created_at / 1000.0);
    END IF;

    -- Fix updated_at if it's bigint
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'updated_at'
        AND data_type = 'bigint'
    ) THEN
        ALTER TABLE users
            ALTER COLUMN updated_at TYPE TIMESTAMP
            USING to_timestamp(updated_at / 1000.0);
    END IF;
END $$;
