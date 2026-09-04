#!/usr/bin/env bash
# Run one or more testbenches. With no arguments, runs every testbench in
# testbenches/. Exits non-zero if any testbench fails, so it is CI-safe.
set -u
cd "$(dirname "$0")/.."

testbench_dir="testbenches/"
to_test=()

if [ $# -eq 0 ]; then
    for file in "$testbench_dir"*.vhd; do
        to_test+=("$(basename "$file" .vhd)")
    done
else
    to_test=("$@")
fi

failed=()
for testbench in "${to_test[@]}"; do
    echo "::group::Running testbench: $testbench"
    if ./scripts/run.sh "$testbench"; then
        echo "PASS: $testbench"
    else
        echo "FAIL: $testbench"
        failed+=("$testbench")
    fi
    echo "::endgroup::"
done

echo
echo "Ran ${#to_test[@]} testbench(es), ${#failed[@]} failed."
if [ ${#failed[@]} -ne 0 ]; then
    echo "Failed testbenches: ${failed[*]}"
    exit 1
fi
echo "All testbenches passed."
