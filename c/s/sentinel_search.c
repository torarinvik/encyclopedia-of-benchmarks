/* Portable sentinel search implementation following the pinned PHP and TypeScript algorithm. */
#include <stddef.h>
#include <stdint.h>

int64_t sentinel_search(int64_t *values, size_t length, int64_t target)
{
    if (length == 0) {
        return -1;
    }

    const size_t last_index = length - 1;
    const int64_t saved_last = values[last_index];
    if (saved_last == target) {
        return (int64_t)last_index;
    }

    values[last_index] = target;
    size_t index = 0;
    while (values[index] != target) {
        ++index;
    }
    values[last_index] = saved_last;

    return index == last_index ? -1 : (int64_t)index;
}
