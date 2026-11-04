#!/usr/bin/env bash
# macos/release.sh <version>, or agvim release <version>: publishes a new version. Checks
# main is clean and pushed, runs the tests, asks, then pushes a version tag. GitHub then
# builds AgVim.dmg and publishes the release (.github/workflows/release.yml), and every
# AgVim updates itself to it the next time it opens (lib/auto-update).
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
version="${1:-}"
stop() {
  echo "agvim release: $1" >&2
  exit 1
}
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || stop "usage: agvim release <version>, such as 1.1.0"
tag="v$version"
[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || stop "switch to main first"
[ -z "$(git status --porcelain)" ] || stop "commit your changes first"
git fetch -q origin main --tags
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || stop "main and origin/main differ: pull or push first"
! git rev-parse -q --verify "refs/tags/$tag" >/dev/null || stop "$tag exists already"

echo "Running the tests. They use separate tmux servers."
tests/run.sh
macos/finder/build.sh >/dev/null 2>&1 # the tests register their own copy

read -r -p "Publish AgVim $version for everyone? (y/N) " answer
[[ "$answer" == [yY]* ]] || { echo "Nothing published."; exit 0; }
git tag -a "$tag" -m "AgVim $version"
git push -q origin "$tag"
echo "Pushed $tag. GitHub is building it: gh run watch, or see"
echo "https://github.com/robertsolves/agvim/actions"
