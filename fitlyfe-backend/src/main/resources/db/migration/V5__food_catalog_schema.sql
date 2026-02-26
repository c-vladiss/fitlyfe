-- ============================================================================
-- V5: Food Catalog Schema
-- Introduces the unified food catalog (food_entries), recipes, and
-- recipe_ingredients. Replaces the minimal foods/meal_foods tables.
-- ============================================================================

-- Enable trigram extension for fuzzy text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------
-- Drop old tables (empty in dev — order matters for FK constraints)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS meal_foods;
DROP TABLE IF EXISTS foods;

-- ---------------------------------------------------------------------------
-- food_entries: unified catalog of foods, branded products, and recipes
-- ---------------------------------------------------------------------------
CREATE TABLE food_entries (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identity
    name                    VARCHAR(500) NOT NULL,
    brand                   VARCHAR(255),
    entry_type              VARCHAR(20)  NOT NULL
                            CHECK (entry_type IN ('FOOD', 'PRODUCT', 'RECIPE')),

    -- Product-specific
    barcode                 VARCHAR(50),
    serving_size_g          DOUBLE PRECISION,

    -- Macronutrients (per 100 g)
    calories_per_100g       DOUBLE PRECISION,
    protein_per_100g        DOUBLE PRECISION,
    carbs_per_100g          DOUBLE PRECISION,
    fat_per_100g            DOUBLE PRECISION,
    fiber_per_100g          DOUBLE PRECISION,
    sugar_per_100g          DOUBLE PRECISION,
    saturated_fat_per_100g  DOUBLE PRECISION,

    -- Micronutrients / vitamins / minerals (JSONB — avoids 40+ nullable columns)
    micronutrients          JSONB,

    -- Provenance
    entry_source            VARCHAR(30)  NOT NULL
                            CHECK (entry_source IN ('USDA', 'OPEN_FOOD_FACTS', 'USER', 'SEED')),
    external_id             VARCHAR(100),
    verified                BOOLEAN      NOT NULL DEFAULT FALSE,
    created_by              UUID         REFERENCES users(user_id),

    created_at              TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at              TIMESTAMP    NOT NULL DEFAULT now()
);

-- Trigram index for fuzzy name search
CREATE INDEX idx_food_entries_name_trgm
    ON food_entries USING GIN (name gin_trgm_ops);

-- Barcode lookup (partial — only products carry barcodes)
CREATE INDEX idx_food_entries_barcode
    ON food_entries (barcode)
    WHERE barcode IS NOT NULL;

-- Filter by type
CREATE INDEX idx_food_entries_entry_type
    ON food_entries (entry_type);

-- Deduplication by external source
CREATE INDEX idx_food_entries_external_id
    ON food_entries (external_id)
    WHERE external_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- recipes: extra metadata for food_entries where entry_type = 'RECIPE'
-- ---------------------------------------------------------------------------
CREATE TABLE recipes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    food_entry_id   UUID         NOT NULL REFERENCES food_entries(id) ON DELETE CASCADE,
    servings        INT          NOT NULL DEFAULT 1,
    serving_label   VARCHAR(50),
    prep_time_min   INT,
    cook_time_min   INT,
    instructions    TEXT,
    created_at      TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP    NOT NULL DEFAULT now(),

    CONSTRAINT uq_recipes_food_entry UNIQUE (food_entry_id)
);

-- ---------------------------------------------------------------------------
-- recipe_ingredients: composition of a recipe from other catalog entries
-- ---------------------------------------------------------------------------
CREATE TABLE recipe_ingredients (
    id              UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id       UUID             NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    food_entry_id   UUID             NOT NULL REFERENCES food_entries(id),
    quantity_g      DOUBLE PRECISION NOT NULL,
    display_amount  DOUBLE PRECISION NOT NULL,
    display_unit    VARCHAR(30)      NOT NULL,
    order_index     INT              NOT NULL DEFAULT 0,
    notes           VARCHAR(255)
);

CREATE INDEX idx_recipe_ingredients_recipe
    ON recipe_ingredients (recipe_id);

-- ---------------------------------------------------------------------------
-- meal_entries: replaces meal_foods — logs a catalog entry consumed in a meal
-- ---------------------------------------------------------------------------
CREATE TABLE meal_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_id         UUID             NOT NULL REFERENCES meals(id) ON DELETE CASCADE,
    food_entry_id   UUID             NOT NULL REFERENCES food_entries(id),
    quantity_g      DOUBLE PRECISION,
    calories        INT,
    protein_g       DOUBLE PRECISION,
    carbs_g         DOUBLE PRECISION,
    fat_g           DOUBLE PRECISION
);

CREATE INDEX idx_meal_entries_meal
    ON meal_entries (meal_id);
