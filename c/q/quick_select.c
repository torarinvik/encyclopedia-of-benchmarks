/* Return the upper median using three-way quickselect on a local copy. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024

static int64_t median_of_three(int64_t first, int64_t middle, int64_t last)
{
    if (first < middle) {
        if (middle < last) return middle;
        return first < last ? last : first;
    }
    if (first < last) return first;
    return middle < last ? last : middle;
}

int64_t quick_select(const int64_t *values, size_t length)
{
    if (length == 0 || length > MAX_VALUES) return -1;
    int64_t scratch[MAX_VALUES];
    for (size_t index = 0; index < length; ++index) scratch[index] = values[index];

    const size_t target = length / 2;
    size_t low = 0;
    size_t high = length;
    while (high - low > 1) {
        const size_t middle = low + (high - low) / 2;
        const int64_t pivot = median_of_three(scratch[low], scratch[middle], scratch[high - 1]);
        size_t less = low;
        size_t scan = low;
        size_t greater = high;
        while (scan < greater) {
            if (scratch[scan] < pivot) {
                const int64_t temporary = scratch[less];
                scratch[less++] = scratch[scan];
                scratch[scan++] = temporary;
            } else if (scratch[scan] > pivot) {
                const int64_t temporary = scratch[--greater];
                scratch[greater] = scratch[scan];
                scratch[scan] = temporary;
            } else {
                ++scan;
            }
        }
        if (target < less) high = less;
        else if (target >= greater) low = greater;
        else return pivot;
    }
    return scratch[target];
}
