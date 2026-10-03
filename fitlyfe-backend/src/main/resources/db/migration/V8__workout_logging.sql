-- ============================================================================
-- V8: Workout logging
-- Exercises are now created from user input and matched by name ignoring case,
-- so enforce that uniqueness in the database. Also index the lookups used when
-- loading and deleting a session.
-- ============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS uq_exercises_name_lower
    ON exercises (lower(name));

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_started
    ON workout_sessions (user_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_workout_exercises_session
    ON workout_exercises (session_id);

CREATE INDEX IF NOT EXISTS idx_exercise_sets_workout_exercise
    ON exercise_sets (workout_exercise_id);

-- ---------------------------------------------------------------------------
-- Idempotent logging: the app generates an id per workout and resends it when
-- it retries after a network failure, so a retry never creates a duplicate.
-- ---------------------------------------------------------------------------
ALTER TABLE workout_sessions ADD COLUMN IF NOT EXISTS client_id UUID;

CREATE UNIQUE INDEX IF NOT EXISTS uq_workout_sessions_user_client_id
    ON workout_sessions (user_id, client_id)
    WHERE client_id IS NOT NULL;
