#include <stdlib.h>
#include "libtci.h"
#include "sorts.h"
#include "bench.h"

int main(void)
{
    size_t const    sizes[3] = {100, 1000, 5000};
    size_t          size_idx;
    size_t          n;
    int             *seed;

    srand(1);
    size_idx = 0;
    while (size_idx < 3) {
        n = sizes[size_idx];
        seed = malloc(n * sizeof(int));
        if (!seed)
            return (1);

        fill_random(seed, n);
        tci_printf("--- random, n=%d ---\n", (int)n);
        bench_one("bubble   ", bubble_sort, "random", seed, n);
        bench_one("insertion", insertion_sort, "random", seed, n);
        bench_one("quicksort", quicksort, "random", seed, n);
        bench_one("qsort    ", qsort_wrapper, "random", seed, n);

        fill_nearly_sorted(seed, n);
        tci_printf("--- nearly sorted, n=%d ---\n", (int)n);
        bench_one("bubble   ", bubble_sort, "nearly_sorted", seed, n);
        bench_one("insertion", insertion_sort, "nearly_sorted", seed, n);
        bench_one("quicksort", quicksort, "nearly_sorted", seed, n);
        bench_one("qsort    ", qsort_wrapper, "nearly_sorted", seed, n);

        fill_sorted(seed, n);
        tci_printf("--- already sorted, n=%d ---\n", (int)n);
        bench_one("bubble   ", bubble_sort, "sorted", seed, n);
        bench_one("insertion", insertion_sort, "sorted", seed, n);
        bench_one("quicksort", quicksort, "sorted", seed, n);
        bench_one("qsort    ", qsort_wrapper, "sorted", seed, n);

        fill_reverse(seed, n);
        tci_printf("--- reverse sorted, n=%d ---\n", (int)n);
        bench_one("bubble   ", bubble_sort, "reverse", seed, n);
        bench_one("insertion", insertion_sort, "reverse", seed, n);
        bench_one("quicksort", quicksort, "reverse", seed, n);
        bench_one("qsort    ", qsort_wrapper, "reverse", seed, n);

        free(seed);
        size_idx++;
    }
    return (0);
}
