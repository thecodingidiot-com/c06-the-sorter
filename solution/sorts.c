#include "sorts.h"

static void swap_ints(int *a, int *b)
{
    int tmp;

    tmp = *a;
    *a = *b;
    *b = tmp;
}

void    bubble_sort(int *arr, size_t n, t_sort_stats *stats)
{
    size_t  i;
    size_t  j;
    int     swapped;

    if (n < 2)
        return;
    i = 0;
    while (i < n - 1)
    {
        swapped = 0;
        j = 0;
        while (j < n - 1 - i)
        {
            stats->comparisons++;
            if (arr[j] > arr[j + 1])
            {
                swap_ints(&arr[j], &arr[j + 1]);
                stats->swaps++;
                swapped = 1;
            }
            j++;
        }
        if (!swapped)
            break;
        i++;
    }
}

void    insertion_sort(int *arr, size_t n, t_sort_stats *stats)
{
    size_t  i;
    size_t  j;
    int     key;

    if (n < 2)
        return;
    i = 1;
    while (i < n)
    {
        key = arr[i];
        j = i;
        while (j > 0)
        {
            stats->comparisons++;
            if (arr[j - 1] <= key)
                break;
            arr[j] = arr[j - 1];
            stats->swaps++;
            j--;
        }
        arr[j] = key;
        i++;
    }
}

static size_t   partition(int *arr, size_t low, size_t high,
        t_sort_stats *stats)
{
    int     pivot;
    size_t  i;
    size_t  j;

    pivot = arr[high];
    i = low;
    j = low;
    while (j < high)
    {
        stats->comparisons++;
        if (arr[j] < pivot)
        {
            swap_ints(&arr[i], &arr[j]);
            stats->swaps++;
            i++;
        }
        j++;
    }
    swap_ints(&arr[i], &arr[high]);
    stats->swaps++;
    return (i);
}

static void quicksort_range(int *arr, size_t low, size_t high,
        t_sort_stats *stats)
{
    size_t  p;

    if (low >= high)
        return;
    p = partition(arr, low, high, stats);
    if (p > low)
        quicksort_range(arr, low, p - 1, stats);
    quicksort_range(arr, p + 1, high, stats);
}

void    quicksort(int *arr, size_t n, t_sort_stats *stats)
{
    if (n < 2)
        return;
    quicksort_range(arr, 0, n - 1, stats);
}
