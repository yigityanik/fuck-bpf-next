#!/usr/bin/env bash
set -euo pipefail

mode="${1:---check}"
case "$mode" in
    --check|--mb) ;;
    *) echo "Usage: bash fuck-bpf-lineage-24.0/apply.sh [--check|--mb]" >&2; exit 2 ;;
esac
source_root="$PWD"
patch_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
projects=(
    kernel/configs
    hardware/interfaces
    system/core
    system/apex
    system/bpf
    packages/modules/Connectivity
    packages/modules/DnsResolver
    system/netd
)

# Preflight the entire series before changing any project.
for project in "${projects[@]}"; do
    target="$source_root/$project"
    patch="$patch_root/$project/0001-Lineage-24.0-legacy-kernel-compatibility.patch"
    if [[ ! -d "$target" ]] || ! git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Missing Git project: $project. Run from the Android source root." >&2
        exit 1
    fi
    git -C "$target" diff --quiet && git -C "$target" diff --cached --quiet || {
        echo "Local changes in $project. Commit or stash them first." >&2; exit 1;
    }
    state="$(git -C "$target" rev-parse --git-path rebase-apply)"
    [[ "$state" = /* ]] || state="$target/$state"
    if [[ -d "$state" ]]; then
        echo "An am/rebase operation is active in $project. Resolve it first." >&2
        exit 1
    fi
    if ! git -C "$target" apply --check --index "$patch"; then
        echo "Preflight failed: $project. See BASE_REVISIONS.json for the tested revision." >&2
        exit 1
    fi
    echo "PASS $project"
done

if [[ "$mode" == --check ]]; then
    echo "All patches passed. Apply with: bash $patch_root/apply.sh --mb"
    exit 0
fi

for project in "${projects[@]}"; do
    if ! git -C "$source_root/$project" am \
        "$patch_root/$project/0001-Lineage-24.0-legacy-kernel-compatibility.patch"; then
        echo "Stopped in $project. Resolve with git am --continue or git am --abort." >&2
        echo "Earlier projects retain their applied commits." >&2
        exit 1
    fi
done
echo "Applied all LineageOS 24.0 legacy kernel patches."
