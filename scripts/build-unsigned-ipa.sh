#!/usr/bin/env bash
set -euo pipefail

repo_dir="${CM_BUILD_DIR:-${GITHUB_WORKSPACE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
XCODE_PROJECT="${XCODE_PROJECT:-Unity-iPhone.xcodeproj}"
XCODE_SCHEME="${XCODE_SCHEME:-Unity-iPhone}"
XCODE_CONFIGURATION="${XCODE_CONFIGURATION:-Release}"
cd "$repo_dir"

project="$repo_dir/$XCODE_PROJECT"
if [[ ! -d "$project" ]]; then
  projects=()
  while IFS= read -r -d '' candidate; do
    projects+=("$candidate")
  done < <(find "$repo_dir" -type d -name 'Unity-iPhone.xcodeproj' -print0)
  if [[ ${#projects[@]} -ne 1 ]]; then
    echo "Set XCODE_PROJECT to the project path relative to the repository root." >&2
    exit 1
  fi
  project="${projects[0]}"
fi
project_dir="$(dirname "$project")"

# Fail early if a library is missing or is still a Git LFS pointer.
for library in libiPhone-lib.a libil2cpp.a baselib.a; do
  library_path="$project_dir/Libraries/$library"
  if [[ ! -f "$library_path" ]]; then
    echo "Missing Unity library: $library_path" >&2
    exit 1
  fi
  if [[ "$(head -c 7 "$library_path")" != '!<arch>' ]]; then
    echo "Invalid library: $library_path. Upload the binary with Git LFS and run git lfs pull." >&2
    exit 1
  fi
done

output_dir="$repo_dir/build/ios-unsigned"
mkdir -p "$output_dir"
xcodebuild -version
xcodebuild \
  -project "$project" \
  -scheme "$XCODE_SCHEME" \
  -configuration "$XCODE_CONFIGURATION" \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$output_dir/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  ENABLE_BITCODE=NO \
  ONLY_ACTIVE_ARCH=NO \
  build 2>&1 | tee "$output_dir/xcodebuild.log"

apps=("$output_dir/DerivedData/Build/Products/$XCODE_CONFIGURATION-iphoneos/"*.app)
if [[ ${#apps[@]} -ne 1 || ! -d "${apps[0]}" ]]; then
  echo "Expected exactly one built .app in $XCODE_CONFIGURATION-iphoneos." >&2
  exit 1
fi
app_path="${apps[0]}"
app_name="$(basename "$app_path" .app)"
package_dir="$(mktemp -d "$output_dir/package.XXXXXX")"
mkdir -p "$package_dir/Payload"
ditto "$app_path" "$package_dir/Payload/$app_name.app"
# Preserve bundle structure and symlinks in the standard Payload layout.
ditto -c -k --norsrc --keepParent "$package_dir/Payload" "$output_dir/$app_name-unsigned.ipa"
unzip -tq "$output_dir/$app_name-unsigned.ipa"
echo "Unsigned IPA: $output_dir/$app_name-unsigned.ipa"
