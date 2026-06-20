#!/usr/bin/env bash
# Usage: gen_changelog.sh <from_tag> <to_tag> [repo]
# from_tag can be empty — then includes all commits up to to_tag
set -euo pipefail

FROM_TAG="${1:-}"
TO_TAG="${2:-HEAD}"
REPO="${3:-}"

if [ -z "$FROM_TAG" ]; then
  COMMITS=$(git log --pretty=format:"%s" "$TO_TAG")
else
  COMMITS=$(git log --pretty=format:"%s" "${FROM_TAG}..${TO_TAG}")
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
  BODY="${BODY}**Full Changelog**: https://github.com/${REPO}/compare/${FROM_TAG}...${TO_TAG}\n"
fi

printf "%b" "$BODY"
