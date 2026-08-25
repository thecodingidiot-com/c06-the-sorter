# c06-the-sorter

Companion repository for **c06 — The Sorter** at
[thecodingidiot.com](https://thecodingidiot.com).

---

## Follow my journey

Working through c06 alongside the implementation pages? Build `sorter`
and `depthvis` step by step, then run the tester.

Clone this repository and copy `test.sh` into your working directory:

```bash
git clone https://github.com/thecodingidiot-com/c06-the-sorter.git
cp c06-the-sorter/test.sh ~/c06-practice/
cd ~/c06-practice
make re
bash test.sh
```

All tests must pass before the chapter is complete.

---

## Follow your journey

Building `sorter` and `depthvis` independently? Here is the full
project brief.

**`sorter`** benchmarks bubble sort, insertion sort, a hand-rolled
quicksort, and libc's `qsort` against the same inputs:

- Three hand-rolled sorts, each with the signature
  `void (int *arr, size_t n, t_sort_stats *stats)`, incrementing
  `stats->comparisons` and `stats->swaps` as they work.
- A `qsort` wrapper matching the same signature, counting comparisons
  via the comparator callback (`stats->swaps` is set to `-1` — not
  measurable from outside the call).
- Four input-generating functions: random, already sorted, reverse
  sorted, and "nearly sorted" (a fully sorted array with 5% of its
  elements swapped to random positions).
- A benchmark loop across three sizes (100, 1,000, 5,000) and all four
  arrangements, timing each run with `clock_gettime(CLOCK_MONOTONIC,
  ...)` and printing elapsed microseconds alongside the comparison and
  swap counts.

Source is split across four files:

| File | Contents |
| --- | --- |
| `main.c` | drives the size/arrangement/algorithm loop |
| `sorts.c` / `sorts.h` | bubble sort, insertion sort, quicksort |
| `bench.c` / `bench.h` | input generators, timing, the `qsort` wrapper |

**`depthvis`** is a small SDL2 program: six overlapping coloured
rectangles ("sprites"), each bobbing on its own sine wave, re-sorted by
depth via `qsort` before every frame is drawn — the painter's algorithm,
running live. `SPACE` toggles the re-sort on and off, to make the visual
difference obvious; `ESC` or closing the window quits.

| File | Contents |
| --- | --- |
| `depthvis.c` | sprite struct, motion, rendering, the SDL2 event loop |

Build links against `libtci.a` and `libtciutil.a` from your working
directory (`sorter` only — `depthvis` links against `libtci.a` and
SDL2, no `libtciutil`).

Build and test your own version first. Use `solution/` to compare once
you are done, not before.

---

## Building the solution

The `solution/` Makefile expects `libtci.a`, `libtciutil.a`, `libtci.h`,
and `libtciutil.h` to be present in the `solution/` directory. Copy them
from your working directory:

```bash
cp libtci.a libtciutil.a libtci.h libtciutil.h c06-the-sorter/solution/
cd c06-the-sorter/solution
make
```

`depthvis` additionally needs `libsdl2-dev` installed (`sdl2-config`
must be on `PATH`) — the same requirement as c04, The Infinite.

---

## What the tester checks

**Build** — both `sorter` and `depthvis` compile with zero warnings.

**`sorter` output shape** — all 48 benchmark lines are present (4
algorithms × 4 arrangements × 3 sizes).

**Known stat invariants:**
- Bubble sort and insertion sort both make zero swaps on already-sorted
  input.
- This chapter's `quicksort` hits its theoretical worst-case comparison
  count — $n(n-1)/2$ — on both already-sorted and reverse-sorted input.
- `qsort`'s counting comparator reports a plausible (positive)
  comparison count.

**`depthvis`** — runs its event loop for two seconds under a headless
(`SDL_VIDEODRIVER=dummy`) video driver without crashing. This is a
smoke test, not a visual check — actually looking at the sort/no-sort
difference is done by running the program yourself.

The exact comparison and swap counts the tester checks assume glibc's
`rand()`/`srand()` sequence, which is consistent across machines running
the same glibc, but is not a portable guarantee across other C
libraries.

---

## License

MIT License. See [LICENSE](LICENSE).
