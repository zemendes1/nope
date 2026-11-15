#!/usr/bin/env bash
# Set the app version and increase the build number by one.
# Usage: scripts/bump-version.sh 0.3
set -euo pipefail

version="${1:?usage: scripts/bump-version.sh <version, e.g. 0.3>}"
cd "$(dirname "$0")/.."
project="nope.xcodeproj/project.pbxproj"

current_build=$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$project" | sed -E 's/.*= ([0-9]+);/\1/')
next_build=$((current_build + 1))

sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = ${version};/" "$project"
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = ${next_build};/" "$project"

echo "Version ${version} (build ${next_build}). Commit this and merge it into master, then run scripts/release.sh."
