#!/bin/bash

# Inspired by https://github.com/kou/arrow/blob/main/ci/scripts/util_free_space.sh

# This only cleans up the largest offender(s)
# If more space is needed, see link above

set -eu

echo "::group::Disk usage before cleanup"
df -h
echo "::endgroup::"

# Function for fast deletion using find
fast_delete() {
  local path="$1"
  if [ -d "$path" ]; then
    sudo find "$path" -type f -delete 2>/dev/null || :
    sudo find "$path" -depth -type d -delete 2>/dev/null || :
  fi
}

echo "::group::Clearing large directories"
declare -a large_dirs=(
  #"/usr/local/lib/android" extra ~9GB but can take minutes to remove
  "/opt/hostedtoolcache/CodeQL"
  "/opt/hostedtoolcache/go"
  "/opt/microsoft/powershell"
)

julia=$(find /usr/local -maxdepth 1 -type d -name "julia*")
if [ -n "$julia" ]; then
  large_dirs+=("$julia")
fi

pids=()
for dir in "${large_dirs[@]}"; do
  if [ -d "$dir" ]; then
    echo "Starting deletion: $dir"
    (fast_delete "$dir"; echo "Completed: $dir") &
    pids+=($!)
  fi
done

# Wait for all background deletions to complete
echo "Waiting for ${#pids[@]} parallel deletions..."
for pid in "${pids[@]}"; do
  wait "$pid" 2>/dev/null || :
done
echo "All deletions complete"
echo "::endgroup::"

echo "::group::Disk usage after cleanup"
df -h
echo "::endgroup::"
