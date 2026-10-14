/* Portable bitonic sorting network for power-of-two lengths. */
#include <stddef.h>
#include <stdint.h>

static void bitonic_compare(int64_t *values, size_t left, size_t right, int ascending)
{
    if ((ascending && values[left] > values[right]) ||
        (!ascending && values[left] < values[right])) {
        const int64_t temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
    }
}

static void bitonic_merge(int64_t *values, size_t low, size_t length, int ascending)
{
    if (length < 2) return;
    const size_t half = length / 2;
    for (size_t index = low; index < low + half; ++index) {
        bitonic_compare(values, index, index + half, ascending);
    }
    bitonic_merge(values, low, half, ascending);
    bitonic_merge(values, low + half, half, ascending);
}

static void bitonic_sort_range(int64_t *values, size_t low, size_t length, int ascending)
{
    if (length < 2) return;
    const size_t half = length / 2;
    bitonic_sort_range(values, low, half, 1);
    bitonic_sort_range(values, low + half, half, 0);
    bitonic_merge(values, low, length, ascending);
}

void bitonic_sort(int64_t *values, size_t length)
{
    if (length < 2) return;
    bitonic_sort_range(values, 0, length, 1);
}
