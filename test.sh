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
# ── leak report ─────────────────────────────────────────────────────────────
#
# Runs one representative invocation under valgrind and REPORTS what it finds.
# It never changes the pass/fail count. A leak is something to look at, not a
# reason to refuse your work — but you should see it, because a program that
# leaks is a program that will eventually be killed by the machine it runs on.
#
# Leaks are split by whose code lost the memory. A loss record whose stack
# names one of your own .c files is yours. One that lives entirely inside
# SDL, Mesa or glibc is not, and there is nothing for you to fix there.

leak_report() {
    local label="$1"; shift
    local log="${WORK_DIR:-/tmp}/leaks.$$.log"
    local mine=0 theirs=0 rec frames

    if ! command -v valgrind >/dev/null 2>&1; then
        printf "  ${C_BOLD}NOTE${C_RESET}  %s: valgrind is not installed, skipping\n" "$label"
        return 0
    fi

    valgrind --leak-check=full --show-leak-kinds=definite,indirect \
             --error-exitcode=0 --log-file="$log" "$@" >/dev/null 2>&1

    if [[ ! -s "$log" ]]; then
        printf "  ${C_BOLD}NOTE${C_RESET}  %s: valgrind produced no output\n" "$label"
        return 0
    fi

    # Split the log into loss records and ask, of each, whether any frame
    # points at a source file sitting in this directory.
    while IFS= read -r rec; do
        frames=$(sed -n "${rec}"',/^==[0-9]*== *$/p' "$log")
        # Every record carries valgrind's own malloc frame; that is not yours.
        # A frame is yours only if it names a source file sitting right here.
        local f owned=0
        for f in $(grep -oE '\(([A-Za-z0-9_-]+\.c):[0-9]+\)' <<<"$frames" \
                   | tr -d '()' | cut -d: -f1 | sort -u); do
            [[ "$f" == vg_replace_malloc.c ]] && continue
            [[ -f "$f" ]] && owned=1
        done
        if (( owned )); then
            mine=$((mine + 1))
            if (( mine == 1 )); then
                printf "  ${C_RED}LEAK${C_RESET}  %s — memory lost by your code:\n" "$label"
            fi
            grep -E 'bytes in [0-9,]+ blocks are (definitely|indirectly)' <<<"$frames" \
                | sed 's/^==[0-9]*== /        /'
            grep -oE '\(([A-Za-z0-9_-]+\.c:[0-9]+)\)' <<<"$frames" \
                | grep -v vg_replace_malloc | head -3 | tr -d '()' \
                | sed 's/^/          at /'
        else
            theirs=$((theirs + 1))
        fi
    done < <(grep -nE 'bytes in [0-9,]+ blocks are (definitely|indirectly) lost' "$log" | cut -d: -f1)

    if (( mine == 0 )); then
        printf "  ${C_GREEN}OK${C_RESET}    %s — no memory lost by your code" "$label"
        if (( theirs > 0 )); then
            printf ' (%d leak(s) inside libraries you did not write)' "$theirs"
        fi
        printf '\n'
    else
        printf '        this does not fail the tester — fix it anyway\n'
    fi
    rm -f "$log"
    return 0
}

# The graphical chapters run until you quit them, and a program killed
# mid-loop reports everything it has not freed yet as "lost" -- which would be
# a lie. So this starts a virtual display, lets the program run, sends it a
# 'q', and measures the clean exit.
leak_report_gui() {
    local label="$1"; shift
    if ! command -v valgrind >/dev/null 2>&1; then
        printf "  ${C_BOLD}NOTE${C_RESET}  %s: valgrind is not installed, skipping\n" "$label"
        return 0
    fi
    if ! command -v xvfb-run >/dev/null 2>&1 || ! command -v xte >/dev/null 2>&1; then
        printf "  ${C_BOLD}NOTE${C_RESET}  %s: needs xvfb-run and xte for a clean exit, skipping\n" "$label"
        return 0
    fi
    printf "  ${C_BOLD}....${C_RESET}  %s: running under valgrind, this takes a minute\n" "$label"
    local inner="${WORK_DIR:-/tmp}/leak_gui.$$.sh"
    {
        echo "C_GREEN=\"${C_GREEN}\"; C_RED=\"${C_RED}\"; C_BOLD=\"${C_BOLD}\"; C_RESET=\"${C_RESET}\""
        echo "WORK_DIR=\"${WORK_DIR:-/tmp}\""
        declare -f leak_report
        echo '( sleep 12; xte "key q" 2>/dev/null; sleep 5; xte "key q" 2>/dev/null ) &'
        printf 'leak_report %q' "$label"
        printf ' %q' "$@"
        printf '\n'
    } > "$inner"
    timeout 240 xvfb-run -a bash "$inner"
    local rc=$?
    rm -f "$inner"
    if (( rc == 124 )); then
        printf "  ${C_BOLD}NOTE${C_RESET}  %s: the program never exited, so there is nothing honest to measure\n" "$label"
        printf "        (a program killed mid-loop reports everything it holds as lost)\n"
    fi
    return 0
}

echo
leak_report "sorter" ./sorter

hr
printf "  ${C_BOLD}%d passed, %d failed${C_RESET}\n" "$pass_count" "$fail_count"
hr

if [[ "$fail_count" -gt 0 ]]; then
    exit 1
fi
exit 0
