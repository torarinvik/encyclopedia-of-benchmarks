/* Divide an inclusive range to find the largest signed 32-bit key. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256

static int64_t find_max_range(const int64_t *values, size_t low, size_t high) {
    if (low == high) return values[low];
    size_t middle = low + (high - low) / 2;
    int64_t left = find_max_range(values, low, middle);
    int64_t right = find_max_range(values, middle + 1, high);
    return left >= right ? left : right;
}

int64_t find_max_recursion(const int64_t *values, size_t length) {
    if (values == NULL || length == 0 || length > MAX_LENGTH) return -1;
    for (size_t i = 0; i < length; ++i) if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -1;
    return find_max_range(values, 0, length - 1);
}
