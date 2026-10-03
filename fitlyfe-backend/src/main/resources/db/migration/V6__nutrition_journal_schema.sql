-- ============================================================================
-- V6: Nutrition Journal Schema
-- Adds user goals, meal templates, and per-day meal ordering
-- ============================================================================

-- ---------------------------------------------------------------------------
-- user_goals: daily calorie and macro targets for each user
-- ---------------------------------------------------------------------------
CREATE TABLE user_goals (
    user_id             UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    daily_calories      INT              NOT NULL DEFAULT 2000,
    daily_protein_g     DOUBLE PRECISION NOT NULL DEFAULT 150.0,
    daily_carbs_g       DOUBLE PRECISION NOT NULL DEFAULT 250.0,
    daily_fat_g         DOUBLE PRECISION NOT NULL DEFAULT 65.0,
    goal_weight_kg      DOUBLE PRECISION,
    created_at          TIMESTAMP        NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP        NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- user_meal_types: default meal template for each user
-- (e.g., Breakfast, Lunch, Dinner, Snack)
-- ---------------------------------------------------------------------------
CREATE TABLE user_meal_types (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID             NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name                VARCHAR(100)     NOT NULL,
    sort_order          INT              NOT NULL,
    is_default          BOOLEAN          NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP        NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP        NOT NULL DEFAULT now(),

    -- Each user can only have one meal type with a given name
    CONSTRAINT uq_user_meal_types_user_name UNIQUE (user_id, name)
);

CREATE INDEX idx_user_meal_types_user
    ON user_meal_types (user_id);

-- ---------------------------------------------------------------------------
-- meals: add sort_order for per-day meal ordering
-- ---------------------------------------------------------------------------
ALTER TABLE meals
    ADD COLUMN sort_order INT NOT NULL DEFAULT 0;

CREATE INDEX idx_meals_daily_nutrition_sort
    ON meals (daily_nutrition_id, sort_order);
