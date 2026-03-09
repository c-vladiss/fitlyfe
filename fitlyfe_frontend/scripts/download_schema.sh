#!/bin/bash
# Downloads GraphQL schema from running backend via introspection
# Requires backend running at localhost:8081

set -e
cd "$(dirname "$0")/.."

BACKEND_URL="${BACKEND_URL:-http://localhost:8081/graphql}"
OUTPUT_FILE="lib/graphql/schema.graphql"

echo "Fetching schema from $BACKEND_URL..."

# Introspection query
QUERY='{"query":"query IntrospectionQuery { __schema { queryType { name } mutationType { name } subscriptionType { name } types { ...FullType } directives { name description locations args { ...InputValue } } } } fragment FullType on __Type { kind name description fields(includeDeprecated: true) { name description args { ...InputValue } type { ...TypeRef } isDeprecated deprecationReason } inputFields { ...InputValue } interfaces { ...TypeRef } enumValues(includeDeprecated: true) { name description isDeprecated deprecationReason } possibleTypes { ...TypeRef } } fragment InputValue on __InputValue { name description type { ...TypeRef } defaultValue } fragment TypeRef on __Type { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name ofType { kind name } } } } } } } }"}'

# Fetch schema via introspection and convert to SDL
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "$QUERY" \
  "$BACKEND_URL" > /tmp/schema_introspection.json

# Check if introspection succeeded
if ! grep -q '"__schema"' /tmp/schema_introspection.json 2>/dev/null; then
  echo "Error: Introspection failed. Is the backend running at $BACKEND_URL?"
  cat /tmp/schema_introspection.json
  exit 1
fi

# For now, we'll concatenate the backend .graphqls files directly
# This is simpler than converting introspection JSON to SDL
BACKEND_SCHEMA_DIR="../fitlyfe-backend/src/main/resources/graphql"

if [ -d "$BACKEND_SCHEMA_DIR" ]; then
  echo "Copying schema files from backend..."
  cat "$BACKEND_SCHEMA_DIR"/common.graphqls \
      "$BACKEND_SCHEMA_DIR"/auth.graphqls \
      "$BACKEND_SCHEMA_DIR"/user.graphqls \
      "$BACKEND_SCHEMA_DIR"/nutrition.graphqls \
      "$BACKEND_SCHEMA_DIR"/food.graphqls \
      "$BACKEND_SCHEMA_DIR"/workout.graphqls \
      > "$OUTPUT_FILE"
  echo "Schema written to $OUTPUT_FILE"
else
  echo "Error: Backend schema directory not found at $BACKEND_SCHEMA_DIR"
  echo "Falling back to introspection (requires graphql-codegen-cli for conversion)"
  exit 1
fi

echo "Done!"
