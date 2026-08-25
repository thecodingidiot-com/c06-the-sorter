#define _POSIX_C_SOURCE 200809L
#include <stdlib.h>
#include <time.h>
#include "libtci.h"
#include "bench.h"

static long g_qsort_comparisons;

static int cmp_ints_counting(void const *a, void const *b)
{
    int const   *ia;
    int const   *ib;

    ia = a;
    ib = b;
    g_qsort_comparisons++;
    return (*ia - *ib);
}

void    qsort_wrapper(int *arr, size_t n, t_sort_stats *stats)
{
    g_qsort_comparisons = 0;
    qsort(arr, n, sizeof(int), cmp_ints_counting);
    stats->comparisons = g_qsort_comparisons;
    stats->swaps = -1;
}

void    fill_random(int *arr, size_t n)
{
    size_t  i;

    i = 0;
    while (i < n)
    {
        arr[i] = rand() % 100000;
        i++;
    }
}

void    fill_sorted(int *arr, size_t n)
{
    size_t  i;

    i = 0;
    while (i < n)
    {
        arr[i] = (int)i;
        i++;
    }
}

void    fill_reverse(int *arr, size_t n)
{
    size_t  i;

    i = 0;
    while (i < n)
    {
        arr[i] = (int)(n - i);
        i++;
    }
}

void    fill_nearly_sorted(int *arr, size_t n)
{
    size_t  i;
    size_t  swap_count;
    size_t  a;
    size_t  b;
    int     tmp;

    fill_sorted(arr, n);
    swap_count = n / 20;
    if (swap_count < 1)
        swap_count = 1;
    i = 0;
    while (i < swap_count)
    {
        a = (size_t)rand() % n;
        b = (size_t)rand() % n;
        tmp = arr[a];
        arr[a] = arr[b];
        arr[b] = tmp;
        i++;
    }
}

static long elapsed_us(struct timespec start, struct timespec end)
{
    long    sec_diff;
    long    nsec_diff;

    sec_diff = (long)(end.tv_sec - start.tv_sec);
    nsec_diff = (long)(end.tv_nsec - start.tv_nsec);
    return (sec_diff * 1000000 + nsec_diff / 1000);
}

void    bench_one(char const *sort_name, t_sort_fn sort,
        char const *arrangement_name, int const *seed, size_t n)
{
    int             *arr;
    t_sort_stats    stats;
    struct timespec start;
    struct timespec end;
    size_t          i;

    arr = malloc(n * sizeof(int));
    if (!arr)
        return;
    i = 0;
    while (i < n)
    {
        arr[i] = seed[i];
        i++;
    }
    stats.comparisons = 0;
    stats.swaps = 0;
    clock_gettime(CLOCK_MONOTONIC, &start);
    sort(arr, n, &stats);
    clock_gettime(CLOCK_MONOTONIC, &end);
    tci_printf("%s / %s / n=%d: %d us, comparisons=%d, swaps=%d\n",
        sort_name, arrangement_name, (int)n,
        (int)elapsed_us(start, end), (int)stats.comparisons,
        (int)stats.swaps);
    free(arr);
}
