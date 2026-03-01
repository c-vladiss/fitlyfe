# FitLyfe

A fitness tracking mobile app with a Flutter frontend and Kotlin/Spring Boot backend.

## Project Structure

```
fitlyfe/
├── fitlyfe_frontend/    # Flutter mobile app (Dart)
├── fitlyfe-backend/     # Spring Boot GraphQL API (Kotlin)
└── README.md            # This file
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile App | Flutter (Dart) |
| Backend API | Spring Boot + GraphQL (Kotlin) |
| Authentication | Supabase Auth (JWT) |
| Database | PostgreSQL 16 |
| Migrations | Flyway |

## Quick Start

See [CLAUDE.md](./CLAUDE.md) for detailed build and run commands.

---

# Backend Documentation

## Services Overview

| Service | Description | Status |
|---------|-------------|--------|
| [Food Catalog Service](#food-catalog-service) | USDA food database integration | ✅ Complete |
| [Nutrition Journal Service](#nutrition-journal-service) | Daily nutrition tracking & meal templates | ✅ Complete |
| User Service | User management & profiles | ✅ Complete |
| Auth Service | Supabase JWT authentication | ✅ Complete |
| Workout Service | Exercise tracking | 🚧 Planned |

---

## Food Catalog Service

Provides food search and nutritional data from USDA FoodData Central.

### Endpoints

| Query | Description |
|-------|-------------|
| `searchFoods(query, limit)` | Search USDA database |
| `foodEntry(id)` | Get food details by ID |

### Features

- USDA FoodData Central integration
- Caching for frequently accessed foods
- Fallback search threshold configuration

---

## Nutrition Journal Service

Manages daily nutrition tracking with customizable meal templates.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Default Template** | User's preferred meal structure (Breakfast, Lunch, Dinner, etc.) |
| **Per-Day Template** | Each day's actual meals - independent from default template |
| **User Goals** | Daily calorie/macro targets distributed across meals |

### Meal Template System

#### How It Works

1. **First query to a day** → Initializes from default template (creates actual meal records)
2. **Adding/deleting meals on a day** → Only affects that specific day
3. **Changing default template** → Only affects future pristine days

#### Day States

| State | Description |
|-------|-------------|
| **Pristine** | Never accessed - no records exist |
| **Active** | Has been accessed - has actual `MealEntity` records |

### API Reference

#### Queries

```graphql
# Get daily nutrition (initializes day if pristine)
dailyNutrition(date: String!): DailyNutrition!

# Get user's default meal template
userMealTypes: [UserMealType!]!

# Get user's daily goals
userGoals: UserGoals!
```

#### Mutations - Default Template (Settings)

```graphql
createUserMealTypes(types: [MealTypeInput!]!): [UserMealType!]!
addUserMealType(name: String!, sortOrder: Int!): UserMealType!
updateUserMealType(id: ID!, name: String, sortOrder: Int): UserMealType!
deleteUserMealType(id: ID!): Boolean!
```

#### Mutations - Per-Day Meals

```graphql
addMealToDay(date: String!, mealType: String!): Meal!
renameMealOnDay(mealId: ID!, newName: String!): Meal!
deleteMealFromDay(mealId: ID!): Boolean!
```

#### Mutations - Meal Entries

```graphql
addMealEntry(date: String!, mealType: String!, foodEntryId: ID!, quantityG: Float!): AddMealEntryResponse!
updateMealEntry(entryId: ID!, quantityG: Float, foodEntryId: ID): MealEntry!
deleteMealEntry(entryId: ID!): Boolean!
```

#### Mutations - User Goals

```graphql
updateUserGoals(
  dailyCalories: Int,
  dailyProteinG: Float,
  dailyCarbsG: Float,
  dailyFatG: Float,
  goalWeightKg: Float
): UserGoals!
```

### Response Types

#### DailyNutrition

```graphql
type DailyNutrition {
    id: ID!
    date: String!
    totalCalories: Int
    proteinG: Float
    carbsG: Float
    fatG: Float
    goals: DailyGoals!
    mealTemplate: [MealSlot!]!
    meals: [Meal!]!
}
```

#### MealSlot (Daily View)

```graphql
type MealSlot {
    name: String!
    sortOrder: Int!
    # Per-meal goals (total / number of meals)
    targetCalories: Int!
    targetProteinG: Float!
    targetCarbsG: Float!
    targetFatG: Float!
    # Consumed totals
    consumedCalories: Int
    consumedProteinG: Float
    consumedCarbsG: Float
    consumedFatG: Float
    # Logged entries (simplified)
    entries: [MealSlotEntry!]!
}
```

#### MealSlotEntry (Simplified)

```graphql
type MealSlotEntry {
    id: ID!
    name: String!
    quantityG: Float
    calories: Int
    proteinG: Float
    carbsG: Float
    fatG: Float
}
```

### Goal Distribution

Goals are distributed equally across the day's meals:

```
Per-meal target = Total daily goal / Number of meals in day
```

**Example:**
- Daily goals: 2000 cal, 150g protein
- Day has 4 meals → 500 cal, 37.5g protein per meal
- Delete one meal → 666 cal, 50g protein per meal

### Database Schema

```sql
-- User's default meal template
CREATE TABLE user_meal_types (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    name VARCHAR NOT NULL,
    sort_order INT NOT NULL,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Per-day meals
CREATE TABLE meals (
    id UUID PRIMARY KEY,
    daily_nutrition_id UUID REFERENCES daily_nutrition(id),
    meal_type VARCHAR,
    sort_order INT DEFAULT 0,
    logged_at TIMESTAMP,
    created_at TIMESTAMP
);

-- Food entries logged to meals
CREATE TABLE meal_entries (
    id UUID PRIMARY KEY,
    meal_id UUID REFERENCES meals(id),
    food_entry_id UUID REFERENCES food_entries(id),
    quantity_g NUMERIC,
    calories INT,
    protein_g NUMERIC,
    carbs_g NUMERIC,
    fat_g NUMERIC,
    created_at TIMESTAMP
);

-- User daily goals
CREATE TABLE user_goals (
    user_id UUID PRIMARY KEY REFERENCES users(user_id),
    daily_calories INT DEFAULT 2000,
    daily_protein_g NUMERIC DEFAULT 150.0,
    daily_carbs_g NUMERIC DEFAULT 250.0,
    daily_fat_g NUMERIC DEFAULT 65.0,
    goal_weight_kg NUMERIC,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### Example Scenarios

#### User skips lunch one day

1. Query March 15 → Initialized with Breakfast, Lunch, Dinner, Snack
2. Call `deleteMealFromDay` for Lunch
3. March 15 now has: Breakfast, Dinner, Snack
4. March 16 (pristine) → Will have full template when queried

#### User adds post-workout meal

1. Query March 15 → Initialized with 4 meals
2. Call `addMealToDay(date: "2026-03-15", mealType: "Post-Workout")`
3. March 15 now has 5 meals
4. Default template unchanged
5. Other days unaffected

#### User changes default template

1. Default: Breakfast, Lunch, Dinner, Snack
2. March 15 already accessed (has 4 meals)
3. Add "Evening Snack" to default template
4. March 15 unchanged (still 4 meals)
5. March 20 (pristine) → Will have 5 meals when queried

### Design Decisions

| Decision | Rationale |
|----------|-----------|
| Per-day templates | Flexibility for custom days (fasting, events) |
| Initialize on first query | No separate "create day" action needed |
| Keep empty meals | Track user behavior patterns |
| Goals per actual meals | Accurate per-meal targets after deletions |

---

# Frontend Documentation

*Documentation for the Flutter mobile app will be added here.*

## Screens

- Welcome / Login
- Onboarding
- Main Dashboard
- Nutrition Journal
- Food Search
- Meal Detail
- Settings

## Providers

- AppState
- NutritionProvider
- WorkoutProvider
- ProgressProvider
- HealthProvider
- LocaleProvider

---

# Development

## Prerequisites

- JDK 17+
- Flutter 3.x
- PostgreSQL 16
- Docker (for Testcontainers)

## Environment Setup

See [CLAUDE.md](./CLAUDE.md) for detailed setup instructions.
