#!/usr/bin/env bash
# Build nope from master, publish a GitHub release, and update the Homebrew tap.
# Usage: scripts/release.sh
#
# Run it on an up-to-date master after the version bump has been merged
# (see scripts/bump-version.sh). The version comes from the Xcode project.
# Set TAP_DIR if the homebrew-tap checkout isn't next to this repo.
set -euo pipefail

cd "$(dirname "$0")/.."
repo_dir=$(pwd)
tap_dir="${TAP_DIR:-$repo_dir/../homebrew-tap}"
cask="$tap_dir/Casks/nope.rb"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

fail() { echo "error: $*" >&2; exit 1; }

# --- Checks -----------------------------------------------------------------
[[ $(git branch --show-current) == master ]] || fail "switch to master first"
git fetch -q origin
[[ $(git rev-parse HEAD) == $(git rev-parse origin/master) ]] || fail "master isn't in sync with origin/master (pull or push first)"
[[ -f "$cask" ]] || fail "Homebrew tap not found at $tap_dir (set TAP_DIR)"
[[ -z $(git -C "$tap_dir" status --porcelain) ]] || fail "the tap has uncommitted changes"

version=$(grep -m1 'MARKETING_VERSION = ' nope.xcodeproj/project.pbxproj | sed -E 's/.*= ([^;]+);/\1/')
tag="v$version"
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && fail "$tag already exists. Run scripts/bump-version.sh and merge it first"
grep -q "version \"$version\"" "$cask" && fail "the cask is already at $version"

echo "Releasing nope $version from $(git rev-parse --short HEAD)"

# --- Build from a clean copy of master ---------------------------------------
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
git archive HEAD | tar -x -C "$work"

(cd "$work" && xcodebuild -project nope.xcodeproj -scheme nope -configuration Release \
  -derivedDataPath "$work/build" ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO build -quiet)

app="$work/build/Build/Products/Release/nope.app"
built_version=$(defaults read "$app/Contents/Info" CFBundleShortVersionString)
[[ $built_version == "$version" ]] || fail "built app says $built_version, expected $version"
codesign --verify --deep --strict "$app" || fail "code signature is invalid"
echo "Built universal app: $(lipo -archs "$app/Contents/MacOS/nope")"

zip="$work/nope-$version.zip"
(cd "$(dirname "$app")" && ditto -c -k --keepParent nope.app "$zip")
sha=$(shasum -a 256 "$zip" | cut -d' ' -f1)

# --- GitHub release ----------------------------------------------------------
notes="### Install

\`\`\`bash
brew upgrade --cask nope   # or: brew install --cask zemendes1/tap/nope
\`\`\`

Or download \`nope-$version.zip\` below, unzip, and move \`nope.app\` to Applications.

nope isn't notarized yet. The first time you open a new version, go to **System Settings → Privacy & Security** and click **Open Anyway**.

Requires macOS 14 or later. Universal app (Apple Silicon and Intel).

---
"
gh release create "$tag" "$zip" --repo zemendes1/nope --target master \
  --title "nope $version" --notes "$notes" --generate-notes

# Make sure what GitHub serves is exactly what we built.
remote_sha=$(curl -sfL "https://github.com/zemendes1/nope/releases/download/$tag/nope-$version.zip" | shasum -a 256 | cut -d' ' -f1)
[[ $remote_sha == "$sha" ]] || fail "downloaded zip doesn't match the built one (got $remote_sha)"

# --- Homebrew tap ------------------------------------------------------------
git -C "$tap_dir" pull -q --ff-only
sed -i '' -E "s/^  version \".*\"/  version \"$version\"/; s/^  sha256 \".*\"/  sha256 \"$sha\"/" "$cask"
git -C "$tap_dir" commit -q -am "Update nope to $version"
git -C "$tap_dir" push -q

git fetch -q --tags
echo
echo "Released nope $version"
echo "  GitHub:   https://github.com/zemendes1/nope/releases/tag/$tag"
echo "  Homebrew: brew upgrade --cask nope"
