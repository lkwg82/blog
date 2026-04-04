#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/run.sh" prod

cd "$SCRIPT_DIR"

dirty=$(git status --porcelain | grep -v '^.. public/' | grep -v '^.. resources/' || true)
if [[ -n "$dirty" ]]; then
  echo "⚠️  Uncommitted changes outside public/ or resources/ — aborting."
  echo "$dirty"
  echo "⚠️  Uncommitted changes outside public/ or resources/ — aborting."
  exit 1
fi

changed=$(git status --porcelain public/ resources/ 2>/dev/null)

if [[ -z "$changed" ]]; then
  echo "Nothing changed in public/ or resources/ — skipping commit."
  exit 0
fi

git add public/ resources/
git commit -m "chore: publish site"

if gum confirm "Push to remote?"; then
  git push
fi
