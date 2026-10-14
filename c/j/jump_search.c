/* Independent portable implementation of TheAlgorithms/C jump search. */
#include <stddef.h>
#include <stdint.h>

static size_t integer_sqrt(size_t value)
{
    if (value < 2) return value;
    size_t low = 1;
    size_t high = value / 2 + 1;
    size_t result = 1;
    while (low <= high) {
        const size_t middle = low + (high - low) / 2;
        if (middle <= value / middle) {
            result = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return result;
}

int64_t jump_search(const int64_t *values, size_t length, int64_t target)
{
    if (length == 0) return -1;
    const size_t step = integer_sqrt(length);
    size_t block_start = 0;
    size_t block_end = step < length ? step : length;

    while (values[block_end - 1] < target) {
        if (block_end == length) return -1;
        block_start = block_end;
        block_end = step > length - block_end ? length : block_end + step;
    }

    for (size_t index = block_start; index < block_end; ++index) {
        if (values[index] == target) return (int64_t)index;
        if (values[index] > target) return -1;
    }
    return -1;
}
