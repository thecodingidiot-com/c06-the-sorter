#!/bin/bash
# c06 — The Sorter / test.sh
#
# Builds sorter and depthvis, then checks:
#   - both binaries build with zero warnings
#   - sorter's benchmark output has the expected shape (48 lines: 4
#     algorithms x 4 arrangements x 3 sizes)
#   - known stat invariants (already-sorted swap counts, quicksort's
#     worst-case comparison count on sorted/reverse input)
#   - depthvis starts, runs its event loop, and does not crash, under a
#     headless (dummy) video driver
#
# Copy this file into your working directory, build with 'make re', then run:
#
#   bash test.sh
#
# The exact comparison/swap counts checked below assume glibc's rand()
# and srand(1) produce the same sequence they do on this curriculum's
# target platform (Linux/glibc) — that holds across machines, but not
# necessarily across other C libraries.

set -o pipefail

# ── colour ────────────────────────────────────────────────────────────────────

if [[ ! -t 1 ]]; then
    C_GREEN=""
    C_RED=""
    C_BOLD=""
    C_RESET=""
else
    C_GREEN="\033[0;32m"
    C_RED="\033[0;31m"
    C_BOLD="\033[1m"
    C_RESET="\033[0m"
fi

# ── state ─────────────────────────────────────────────────────────────────────

pass_count=0
fail_count=0

# ── helpers ───────────────────────────────────────────────────────────────────

hr() {
    echo "────────────────────────────────────────────────────────────────"
}

banner() {
    hr
    echo "  c06 — The Sorter / test.sh"
    hr
}

pass() {
    local label="$1"
    printf "  ${C_GREEN}PASS${C_RESET}  %s\n" "$label"
    pass_count=$((pass_count + 1))
}

fail() {
    local label="$1"
    local detail="${2:-}"
    printf "  ${C_RED}FAIL${C_RESET}  %s\n" "$label"
    if [[ -n "$detail" ]]; then
        echo "        $detail"
    fi
    fail_count=$((fail_count + 1))
}

check_invariant() {
    local label="$1"
    local pattern="$2"
    local expect="$3"
    local line

    line=$(echo "$sorter_out" | grep -E "$pattern")
    if [[ -z "$line" ]]; then
        fail "$label" "no line matched: $pattern"
        return
    fi
    if echo "$line" | grep -q "$expect"; then
        pass "$label"
    else
        fail "$label" "got: $line"
    fi
}

banner

# ── build ─────────────────────────────────────────────────────────────────────

echo "Building..."
build_log=$(make re 2>&1)
build_status=$?
if [[ "$build_status" -ne 0 ]]; then
    fail "build succeeds" "make re failed:"
    echo "$build_log"
    exit 1
fi
pass "build succeeds"

if echo "$build_log" | grep -qi "warning"; then
    fail "build produces no warnings" "$(echo "$build_log" | grep -i warning)"
else
    pass "build produces no warnings"
fi

if [[ -x ./sorter ]]; then
    pass "sorter binary exists"
else
    fail "sorter binary exists"
fi

if [[ -x ./depthvis ]]; then
    pass "depthvis binary exists"
else
    fail "depthvis binary exists"
fi

# ── sorter: output shape ──────────────────────────────────────────────────────

echo
echo "Running sorter..."
sorter_out=$(./sorter)

line_count=$(echo "$sorter_out" | grep -cE " / .* / n=[0-9]+: [0-9]+ us, comparisons=[0-9]+, swaps=(-1|[0-9]+)")
if [[ "$line_count" -eq 48 ]]; then
    pass "sorter prints all 48 benchmark lines (4 algorithms x 4 arrangements x 3 sizes)"
else
    fail "sorter prints all 48 benchmark lines" "found $line_count"
fi

# ── sorter: known invariants ──────────────────────────────────────────────────

check_invariant "bubble makes zero swaps on already-sorted input (n=1000)" \
    "^bubble.*/ sorted / n=1000:" "swaps=0"
check_invariant "insertion makes zero swaps on already-sorted input (n=1000)" \
    "^insertion.*/ sorted / n=1000:" "swaps=0"
check_invariant "quicksort hits its worst-case comparison count on already-sorted input (n=1000)" \
    "^quicksort.*/ sorted / n=1000:" "comparisons=499500"
check_invariant "quicksort hits its worst-case comparison count on reverse-sorted input (n=1000)" \
    "^quicksort.*/ reverse / n=1000:" "comparisons=499500"
check_invariant "qsort reports a comparison count via the counting comparator" \
    "^qsort.*/ random / n=5000:" "comparisons=[0-9]"

# ── depthvis: headless smoke test ─────────────────────────────────────────────

echo
echo "Running depthvis headless (2s)..."
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy timeout 2 ./depthvis
depthvis_status=$?
if [[ "$depthvis_status" -eq 124 ]]; then
    pass "depthvis runs its event loop for 2s without crashing"
else
    fail "depthvis runs its event loop for 2s without crashing" "exit code: $depthvis_status"
fi

# ── summary ───────────────────────────────────────────────────────────────────

echo
hr
printf "  ${C_BOLD}%d passed, %d failed${C_RESET}\n" "$pass_count" "$fail_count"
hr

if [[ "$fail_count" -gt 0 ]]; then
    exit 1
fi
exit 0
