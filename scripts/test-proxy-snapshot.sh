#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$project_root/build/proxy-snapshot-tests"
mkdir -p "$build_dir"

xcrun swiftc -module-cache-path "$build_dir/ModuleCache" \
    "$project_root"/MPS/MPS/Models/*.swift \
    "$project_root"/MPS/MPS/Services/*.swift \
    "$project_root/MPS/MPS/ViewModels/ProxyViewModel.swift" \
    "$project_root/Tests/ProxySnapshotTests.swift" \
    -o "$build_dir/ProxySnapshotTests"

"$build_dir/ProxySnapshotTests"
