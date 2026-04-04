#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PORT=1313
BASE_URL="http://localhost:$PORT"

if curl -sf "http://localhost:1313" -o /dev/null; then
  echo using hug dev
else
  python3 -m http.server "$PORT" --directory "$SCRIPT_DIR/public" &
  SERVER_PID=$!
  trap 'kill "$SERVER_PID"' EXIT
fi

# wait for server to be ready
until curl -sf "$BASE_URL" > /dev/null 2>&1; do sleep 0.1; done

links=$(mktemp)

lychee --dump "$BASE_URL" | sort -u | grep "^$BASE_URL" > "$links"
echo "$BASE_URL" >> "$links"

# shellcheck disable=SC2054
LYCHEE_OPTS=(--accept 200,302)

echo "🔍 Checking $(wc -l < "$links") links..."
lychee "${LYCHEE_OPTS[@]}" --files-from "$links"

