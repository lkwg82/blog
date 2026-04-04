#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=1313
BASE_URL="http://localhost:$PORT"

if curl -sf "http://localhost:1313" -o /dev/null; then
  echo using hugo dev
else
  python3 -m http.server "$PORT" --directory "$SCRIPT_DIR/public" &
  SERVER_PID=$!
  trap 'kill "$SERVER_PID"' EXIT
fi

# wait for server to be ready
until curl -sf "$BASE_URL" > /dev/null 2>&1; do sleep 0.1; done

# shellcheck disable=SC2054
LYCHEE_OPTS=(--accept "200,302" --cache --max-cache-age 1h --suggest --archive wayback)

# Collect all post page URLs
post_pages=$(mktemp)
lychee --dump "$BASE_URL" | sort -u | grep "^${BASE_URL}/posts/" > "$post_pages"

echo "🔍 Found $(wc -l < "$post_pages") post pages to check..."
cat "$post_pages"
while IFS= read -r page_url; do
  echo " ... $page_url ..."
  lychee  "${LYCHEE_OPTS[@]}" "$page_url"
done < "$post_pages"

rm -f "$post_pages"
echo "✨ Done!"