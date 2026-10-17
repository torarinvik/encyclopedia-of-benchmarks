#include <stddef.h>
#include <stdint.h>

static int64_t median_of_three(int64_t a, int64_t b, int64_t c)
{
    if (a <= b) {
        if (b <= c) return b;
        if (a <= c) return c;
        return a;
    }
    if (b >= c) return b;
    if (a >= c) return c;
    return a;
}

static size_t partition_range(int64_t *values, size_t left, size_t right)
{
    const size_t middle = left + (right - left) / 2;
    const int64_t pivot = median_of_three(values[left], values[middle], values[right]);
    size_t nleft = left;
    size_t nright = right;
    for (;;) {
        while (values[nleft] < pivot) ++nleft;
        while (values[nright] > pivot) --nright;
        if (nleft >= nright) return nright;
        const int64_t temporary = values[nleft];
        values[nleft] = values[nright];
        values[nright] = temporary;
        ++nleft;
        --nright;
    }
}

static void sort_range(int64_t *values, size_t left, size_t right)
{
    if (left >= right) return;
    const size_t pivot = partition_range(values, left, right);
    sort_range(values, left, pivot);
    sort_range(values, pivot + 1, right);
}

void median_of_three_quick_sorter(int64_t *values, size_t length)
{
    if (length > 1 && values != NULL) sort_range(values, 0, length - 1);
}
