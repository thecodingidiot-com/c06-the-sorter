#ifndef SORTS_H
# define SORTS_H

# include <stddef.h>

typedef struct s_sort_stats
{
    long    comparisons;
    long    swaps;
}   t_sort_stats;

void    bubble_sort(int *arr, size_t n, t_sort_stats *stats);
void    insertion_sort(int *arr, size_t n, t_sort_stats *stats);
void    quicksort(int *arr, size_t n, t_sort_stats *stats);

#endif
