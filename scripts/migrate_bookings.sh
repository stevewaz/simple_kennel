#!/bin/bash
# PawBook — Add customer_id + check_in_time fields to PocketBase bookings collection
# Usage: bash scripts/migrate_bookings.sh

set -e

PB_URL="https://simplekennel.pockethost.io"

echo "PawBook — bookings schema migration"
echo "Target: $PB_URL"
echo ""

# ── Prerequisites ────────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required.  brew install jq"
  exit 1
fi

# ── Credentials ──────────────────────────────────────────────────────────────
read -rp  "Admin email:    " EMAIL
read -rsp "Admin password: " PASSWORD
echo ""
echo ""

# ── 1. Authenticate ──────────────────────────────────────────────────────────
echo "→ Authenticating..."
AUTH=$(curl -s -X POST "$PB_URL/api/_superusers/auth-with-password" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

TOKEN=$(echo "$AUTH" | jq -r '.token // empty')
if [ -z "$TOKEN" ]; then
  echo "✗ Auth failed — check your email/password"
  echo "$AUTH" | jq '.message // .' 2>/dev/null || echo "$AUTH"
  exit 1
fi
echo "✓ Authenticated"

# ── 2. Fetch current bookings collection ─────────────────────────────────────
echo "→ Fetching bookings collection..."
COLLECTION=$(curl -s "$PB_URL/api/collections/bookings" \
  -H "Authorization: $TOKEN")

COL_NAME=$(echo "$COLLECTION" | jq -r '.name // empty')
if [ -z "$COL_NAME" ]; then
  echo "✗ Could not fetch bookings collection"
  echo "$COLLECTION" | jq '.message // .' 2>/dev/null || echo "$COLLECTION"
  exit 1
fi
echo "✓ Collection found"

# ── 3. Check which fields are missing ────────────────────────────────────────
echo "→ Checking fields..."

HAS_CID=$(echo "$COLLECTION"   | jq '[.fields[]? | select(.name == "customer_id")]   | length')
HAS_CIT=$(echo "$COLLECTION"   | jq '[.fields[]? | select(.name == "check_in_time")] | length')

UPDATED="$COLLECTION"
CHANGED=0

if [ "$HAS_CID" = "0" ]; then
  echo "  + adding customer_id"
  UPDATED=$(echo "$UPDATED" | jq '.fields += [{
    "type": "text",
    "name": "customer_id",
    "required": false,
    "system": false,
    "presentable": false,
    "options": {"min": null, "max": null, "pattern": ""}
  }]')
  CHANGED=1
else
  echo "  ✓ customer_id already exists"
fi

if [ "$HAS_CIT" = "0" ]; then
  echo "  + adding check_in_time"
  UPDATED=$(echo "$UPDATED" | jq '.fields += [{
    "type": "text",
    "name": "check_in_time",
    "required": false,
    "system": false,
    "presentable": false,
    "options": {"min": null, "max": null, "pattern": ""}
  }]')
  CHANGED=1
else
  echo "  ✓ check_in_time already exists"
fi

# ── 4. Apply patch if anything changed ───────────────────────────────────────
if [ "$CHANGED" = "0" ]; then
  echo ""
  echo "✓ Nothing to do — all fields already present."
  exit 0
fi

echo "→ Patching collection..."
RESULT=$(curl -s -X PATCH "$PB_URL/api/collections/bookings" \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$UPDATED")

OK=$(echo "$RESULT" | jq -r '.name // empty')
if [ "$OK" = "bookings" ]; then
  echo ""
  echo "✓ Migration complete!"
  echo "  Fields added to bookings:"
  [ "$HAS_CID" = "0" ] && echo "    • customer_id"
  [ "$HAS_CIT" = "0" ] && echo "    • check_in_time"
else
  echo "✗ Patch failed:"
  echo "$RESULT" | jq '.message // .' 2>/dev/null || echo "$RESULT"
  exit 1
fi
