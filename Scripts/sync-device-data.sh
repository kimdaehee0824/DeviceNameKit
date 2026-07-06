#!/usr/bin/env bash
# Syncs DeviceName/*.json (served to 1.x clients via raw.githubusercontent.com)
# into the resources bundled with the 2.x package.
# Run this after editing any file in DeviceName/.
set -euo pipefail
cd "$(dirname "$0")/.."

rm -rf Sources/DeviceNameKit/Resources/DeviceName
mkdir -p Sources/DeviceNameKit/Resources/DeviceName
cp DeviceName/*.json Sources/DeviceNameKit/Resources/DeviceName/

echo "Synced $(ls DeviceName/*.json | wc -l | tr -d ' ') data files into package resources."
