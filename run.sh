#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-}"

dev() {
  hugo server \
    --buildDrafts \
    --enableGitInfo \
    --navigateToChanged \
    --cleanDestinationDir \
    --printPathWarnings \
    --minify
}

prod() {
  hugo \
    --cleanDestinationDir \
    --minify
}

case "$COMMAND" in
  dev)  dev  ;;
  prod) prod ;;
  *)
    echo "Usage: $0 {dev|prod}"
    exit 1
    ;;
esac
