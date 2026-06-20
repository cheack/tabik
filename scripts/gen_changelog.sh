#!/usr/bin/env bash
# Usage: gen_changelog.sh <from_tag> <to_ref> [repo] [display_to_tag]
# to_ref   — git ref used for log (e.g. HEAD); must exist
# display_to_tag — tag name used in the Full Changelog URL (defaults to to_ref)
set -euo pipefail

FROM_TAG="${1:-}"
TO_REF="${2:-HEAD}"
REPO="${3:-}"
DISPLAY_TO="${4:-$TO_REF}"

if [ -z "$FROM_TAG" ]; then
  COMMITS=$(git log --pretty=format:"%s" "$TO_REF")
else
  COMMITS=$(git log --pretty=format:"%s" "${FROM_TAG}..${TO_REF}")
fi

FEATURES=""
FIXES=""
IMPROVEMENTS=""

while IFS= read -r line; do
  if [[ "$line" =~ ^feat:[[:space:]](.+) ]]; then
    FEATURES="${FEATURES}- ${BASH_REMATCH[1]}\n"
  elif [[ "$line" =~ ^fix:[[:space:]](.+) ]]; then
    FIXES="${FIXES}- ${BASH_REMATCH[1]}\n"
  elif [[ "$line" =~ ^refactor:[[:space:]](.+) ]]; then
    IMPROVEMENTS="${IMPROVEMENTS}- ${BASH_REMATCH[1]}\n"
  fi
done <<< "$COMMITS"

BODY=""
[ -n "$FEATURES" ]     && BODY="${BODY}### What's New\n${FEATURES}\n"
[ -n "$FIXES" ]        && BODY="${BODY}### Bug Fixes\n${FIXES}\n"
[ -n "$IMPROVEMENTS" ] && BODY="${BODY}### Improvements\n${IMPROVEMENTS}\n"

if [ -n "$FROM_TAG" ] && [ -n "$REPO" ]; then
  BODY="${BODY}**Full Changelog**: https://github.com/${REPO}/compare/${FROM_TAG}...${DISPLAY_TO}\n"
fi

printf "%b" "$BODY"
