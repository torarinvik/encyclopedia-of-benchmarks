/* Binary search over a monotone sequence in either direction. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS INT64_C(99999)

int64_t order_agnostic_binary_search(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > 100001) return -1;
    const int64_t target = values[0];
    const int64_t count = values[1];
    if (target < INT32_MIN || target > INT32_MAX || count < 1 || count > MAX_ITEMS ||
        length != (size_t)count + 2) return -1;

    const int ascending = values[2] < values[(size_t)count + 1];
    int64_t start = 0, end = count - 1;
    while (start <= end) {
        const int64_t middle = start + (end - start) / 2;
        const int64_t value = values[(size_t)middle + 2];
        if (value == target) return middle;
        if (ascending) {
            if (value < target) start = middle + 1;
            else end = middle - 1;
        } else {
            if (value > target) start = middle + 1;
            else end = middle - 1;
        }
    }
    return -1;
}
