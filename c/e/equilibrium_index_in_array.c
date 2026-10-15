/* Return the first index with equal left and right sums. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024
#define MIN_I32 (-2147483647LL - 1)
#define MAX_I32 2147483647LL

int64_t equilibrium_index_in_array(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_LENGTH + 1) return -2;
    const int64_t n = values[0];
    if (n < 0 || n > MAX_LENGTH || length != (size_t)n + 1) return -2;
    int64_t total = 0;
    for (size_t i = 1; i < length; ++i) {
        if (values[i] < MIN_I32 || values[i] > MAX_I32) return -2;
        total += values[i];
    }
    int64_t left = 0;
    for (int64_t i = 0; i < n; ++i) {
        total -= values[(size_t)i + 1];
        if (left == total) return i;
        left += values[(size_t)i + 1];
    }
    return -1;
}
