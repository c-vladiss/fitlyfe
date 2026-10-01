-- ============================================================================
-- V7: Align the Flyway-managed schema with the JPA entities
--
-- Until now Hibernate ran with ddl-auto=update, which silently patched the
-- schema at startup. That hid two gaps between the migrations and the
-- entities, so a database built from migrations alone did not match:
--   * user_profiles.goal / weight_kg were only ever created by Hibernate
--   * several measurement columns were NUMERIC, while the entities map Double
--     (DOUBLE PRECISION), which fails ddl-auto=validate
--
-- Every statement is idempotent so this is safe both on a fresh database and
-- on one that Hibernate has already patched.
-- ============================================================================

ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS goal      VARCHAR(255);
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS weight_kg DOUBLE PRECISION;

ALTER TABLE user_profiles     ALTER COLUMN height_cm       TYPE DOUBLE PRECISION;
ALTER TABLE user_weights      ALTER COLUMN weight_kg       TYPE DOUBLE PRECISION;

ALTER TABLE user_measurements ALTER COLUMN waist_cm        TYPE DOUBLE PRECISION;
ALTER TABLE user_measurements ALTER COLUMN neck_cm         TYPE DOUBLE PRECISION;
ALTER TABLE user_measurements ALTER COLUMN chest_cm        TYPE DOUBLE PRECISION;
ALTER TABLE user_measurements ALTER COLUMN hip_cm          TYPE DOUBLE PRECISION;
ALTER TABLE user_measurements ALTER COLUMN arm_cm          TYPE DOUBLE PRECISION;
ALTER TABLE user_measurements ALTER COLUMN thigh_cm        TYPE DOUBLE PRECISION;
ALTER TABLE user_measurements ALTER COLUMN body_fat_pct    TYPE DOUBLE PRECISION;

ALTER TABLE exercise_sets     ALTER COLUMN weight_kg       TYPE DOUBLE PRECISION;
ALTER TABLE exercise_sets     ALTER COLUMN distance_meters TYPE DOUBLE PRECISION;

ALTER TABLE daily_nutrition   ALTER COLUMN protein_g       TYPE DOUBLE PRECISION;
ALTER TABLE daily_nutrition   ALTER COLUMN carbs_g         TYPE DOUBLE PRECISION;
ALTER TABLE daily_nutrition   ALTER COLUMN fat_g           TYPE DOUBLE PRECISION;
