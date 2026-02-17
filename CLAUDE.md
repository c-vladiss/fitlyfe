# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FitLyfe is a fitness tracking mobile app with a Flutter frontend and Kotlin/Spring Boot backend. The app uses Supabase for authentication and a PostgreSQL database for persistence.

## Repository Structure

- `fitlyfe_frontend/` - Flutter mobile app (Dart)
- `fitlyfe-backend/` - Spring Boot GraphQL API (Kotlin)

## Build and Run Commands

### Backend (from `fitlyfe-backend/`)

```bash
# Run the application (requires .env file or environment variables)
./gradlew bootRun

# Run tests (uses Testcontainers for Postgres and Keycloak)
./gradlew check

# Build JAR
./gradlew build
```

Backend requires environment variables: `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `SUPABASE_URL`. Copy `.env.example` to `.env` for local development.

### Frontend (from `fitlyfe_frontend/`)

```bash
# Install dependencies
flutter pub get

# Run with config (required - config contains Supabase keys, Google OAuth IDs, API URL)
flutter run --dart-define-from-file=config/dev.json

# iOS simulator (use localhost for API)
flutter run --dart-define-from-file=config/dev.json -d iPhone

# Android emulator (use 10.0.2.2 for API - see config/dev.json.example)
flutter run --dart-define-from-file=config/dev.json -d emulator

# Analyze code
flutter analyze

# Run tests
flutter test
```

Create `config/dev.json` from `config/dev.json.example` with your Supabase and Google OAuth credentials.

## Architecture

### Authentication Flow

1. User signs in via Google/Apple OAuth in Flutter app using Supabase Auth
2. Flutter app receives Supabase JWT access token
3. App calls backend `syncUser` GraphQL mutation with JWT in Authorization header
4. Backend validates JWT against Supabase JWKS (`${SUPABASE_URL}/auth/v1/.well-known/jwks.json`)
5. Backend upserts user record and returns whether onboarding is needed

### Backend Architecture (Spring Boot)

- **GraphQL API**: Schema files in `src/main/resources/graphql/*.graphqls`, controllers annotated with `@Controller` using `@MutationMapping`/`@QueryMapping`
- **Domain modules**: `api/auth`, `api/user`, `api/workout`, `api/nutrition`, `api/tracking`, `api/membership`
- **Each module** typically has: `entity/`, `repository/`, `service/`, `controller/`
- **Database migrations**: Flyway migrations in `src/main/resources/db/migration/`
- **Security**: JWT validation via Spring Security OAuth2 Resource Server, `@PreAuthorize("isAuthenticated()")` on protected endpoints
- **Testing**: Extend `AbstractIntegrationTest` for integration tests - uses Testcontainers for PostgreSQL and Keycloak

### Frontend Architecture (Flutter)

- **State management**: Provider pattern with ChangeNotifier classes in `lib/providers/`
- **Core providers**: `AppState` (auth state, user sync), `NutritionProvider`, `WorkoutProvider`, `ProgressProvider`, `HealthProvider`, `LocaleProvider`
- **Auth strategies**: `lib/auth/` contains platform-specific OAuth implementations (Google, Apple)
- **GraphQL client**: `lib/services/graphql_service.dart` - injects Supabase JWT into requests
- **Config**: Compile-time config via `--dart-define-from-file`, validated in `lib/config/app_config.dart`
- **Localization**: Generated files in `lib/l10n/generated/`, supports 15+ languages
- **Screens**: `lib/screens/` - main app screens including onboarding flow
- **Widgets**: `lib/widgets/` - reusable UI components

### Key Data Flow

1. `AppState.onAuthStateChange()` listens to Supabase auth events
2. On sign-in, calls `GraphQLService.syncUser()` to upsert user on backend
3. Backend returns `requiresOnboarding` flag which drives app navigation
4. `main.dart` uses `_resolveHome()` to show WelcomeScreen, OnboardingScreen, or MainScreen based on auth/onboarding state

### GraphQL Schema

Schema is split across multiple files in `fitlyfe-backend/src/main/resources/graphql/`:
- `common.graphqls` - base Query/Mutation types
- `auth.graphqls` - syncUser, completeOnboarding mutations
- `user.graphqls`, `workout.graphqls`, `nutrition.graphqls` - domain-specific operations

Backend runs GraphiQL at `/graphiql` when enabled.
