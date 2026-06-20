#!/usr/bin/env bash
# Usage: scripts/release.sh <version>
# Updates CHANGELOG.md, commits, tags, and pushes.
set -euo pipefail

VERSION="${1:-}"
REPO="cheack/tabik"

if [ -z "$VERSION" ]; then
  echo "Usage: make release VERSION=1.0.1"
  exit 1
fi

PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
DATE=$(date +%Y-%m-%d)

BODY=$(bash "$(dirname "$0")/gen_changelog.sh" "$PREV_TAG" "$VERSION" "$REPO")
NEW_SECTION="## [${VERSION}] - ${DATE}\n\n${BODY}\n---\n\n"

if [ -f CHANGELOG.md ]; then
  EXISTING=$(tail -n +3 CHANGELOG.md)
  printf "# Changelog\n\n%b%s" "$NEW_SECTION" "$EXISTING" > CHANGELOG.md
else
  printf "# Changelog\n\n%b" "$NEW_SECTION" > CHANGELOG.md
fi

git add CHANGELOG.md
git commit -m "chore: update changelog for ${VERSION}"
git tag -a "${VERSION}" -m "${VERSION}"
git push origin master
git push origin "refs/tags/${VERSION}"
