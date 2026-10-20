#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <testbench>" >&2
    exit 1
fi

scripts_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
testbench=$1

mapfile -d '' -t sources < <(
    find "$scripts_dir/src" "$scripts_dir/tst" -type f \
        \( -iname '*.vhd' -o -iname '*.vhdl' \) -print0
)

sim_dir="$scripts_dir/../sim"
mkdir -p "$sim_dir"
cd "$sim_dir"

ghdl -i --std=08 --workdir="$sim_dir" "${sources[@]}"
ghdl -m --std=08 --workdir="$sim_dir" "$testbench"
ghdl -r --std=08 --workdir="$sim_dir" "$testbench" --wave="$testbench.ghw"
exec gtkwave "$testbench.ghw"
