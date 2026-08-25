#ifndef BENCH_H
# define BENCH_H

# include <stddef.h>
# include "sorts.h"

typedef void (*t_sort_fn)(int *, size_t, t_sort_stats *);

void    qsort_wrapper(int *arr, size_t n, t_sort_stats *stats);
void    fill_random(int *arr, size_t n);
void    fill_sorted(int *arr, size_t n);
void    fill_reverse(int *arr, size_t n);
void    fill_nearly_sorted(int *arr, size_t n);
void    bench_one(char const *sort_name, t_sort_fn sort,
        char const *arrangement_name, int const *seed, size_t n);

#endif
