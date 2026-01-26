#!/bin/bash

set -e

# Get the git revision (short commit hash)
GIT_REVISION=$(git -C "${SRCROOT}" rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Path to the source Info.plist
INFO_PLIST="${SRCROOT}/Tweety/Info.plist"

# Update the GitRevision value
/usr/libexec/PlistBuddy -c "Set :GitRevision $GIT_REVISION" "$INFO_PLIST"

echo "✓ Updated GitRevision to: $GIT_REVISION"
