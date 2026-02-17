CREATE TABLE users (
    id UUID PRIMARY KEY,
    keycloak_id UUID NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    status VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    display_name VARCHAR(255),
    phone VARCHAR(50),
    gender VARCHAR(50),
    date_of_birth DATE,
    height_cm NUMERIC(5,2),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE user_memberships (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    provider VARCHAR(50),
    product_id VARCHAR(255),
    transaction_id VARCHAR(255),
    original_transaction_id VARCHAR(255),
    starts_at TIMESTAMP,
    expires_at TIMESTAMP,
    auto_renew BOOLEAN,
    status VARCHAR(50),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE user_measurements (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    measured_at TIMESTAMP NOT NULL,
    waist_cm NUMERIC(5,2),
    neck_cm NUMERIC(5,2),
    chest_cm NUMERIC(5,2),
    hip_cm NUMERIC(5,2),
    arm_cm NUMERIC(5,2),
    thigh_cm NUMERIC(5,2),
    body_fat_pct NUMERIC(4,2),
    notes TEXT,
    created_at TIMESTAMP
);

CREATE TABLE user_weights (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    measured_at TIMESTAMP NOT NULL,
    weight_kg NUMERIC(5,2),
    source VARCHAR(50),
    created_at TIMESTAMP
);

CREATE TABLE exercises (
    id UUID PRIMARY KEY,
    name VARCHAR(255) UNIQUE,
    muscle_group VARCHAR(100),
    equipment VARCHAR(100),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE workout_sessions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    duration_seconds INTEGER,
    workout_type VARCHAR(50),
    calories_burned INTEGER,
    notes TEXT,
    created_at TIMESTAMP
);

CREATE TABLE workout_exercises (
    id UUID PRIMARY KEY,
    session_id UUID REFERENCES workout_sessions(id),
    exercise_id UUID REFERENCES exercises(id),
    order_index INTEGER,
    notes TEXT
);

CREATE TABLE exercise_sets (
    id UUID PRIMARY KEY,
    workout_exercise_id UUID REFERENCES workout_exercises(id),
    set_number INTEGER,
    reps INTEGER,
    weight_kg NUMERIC(6,2),
    duration_seconds INTEGER,
    distance_meters NUMERIC(10,2)
);

CREATE TABLE foods (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    brand VARCHAR(255),
    calories_per_100g INTEGER,
    protein_per_100g NUMERIC(6,2),
    carbs_per_100g NUMERIC(6,2),
    fat_per_100g NUMERIC(6,2),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE daily_nutrition (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    date DATE NOT NULL,
    total_calories INTEGER,
    protein_g NUMERIC(6,2),
    carbs_g NUMERIC(6,2),
    fat_g NUMERIC(6,2),
    water_ml INTEGER,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    UNIQUE(user_id, date)
);

CREATE TABLE meals (
    id UUID PRIMARY KEY,
    daily_nutrition_id UUID REFERENCES daily_nutrition(id),
    meal_type VARCHAR(50),
    logged_at TIMESTAMP,
    created_at TIMESTAMP
);

CREATE TABLE meal_foods (
    id UUID PRIMARY KEY,
    meal_id UUID REFERENCES meals(id),
    food_id UUID REFERENCES foods(id),
    quantity_g NUMERIC(6,2),
    calories INTEGER,
    protein_g NUMERIC(6,2),
    carbs_g NUMERIC(6,2),
    fat_g NUMERIC(6,2)
);

CREATE TABLE daily_steps (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    date DATE,
    steps INTEGER,
    source VARCHAR(50),
    created_at TIMESTAMP,
    UNIQUE(user_id, date, source)
);
