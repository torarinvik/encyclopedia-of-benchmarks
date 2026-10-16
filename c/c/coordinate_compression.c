/* Map values to ranks among sorted distinct coordinates. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_N 128

static int compare_i64(const void *left, const void *right)
{
    const int64_t a = *(const int64_t *)left;
    const int64_t b = *(const int64_t *)right;
    return (a > b) - (a < b);
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static size_t lower_bound_i64(const int64_t *values, size_t length, int64_t target)
{
    size_t low = 0, high = length;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (values[middle] < target) low = middle + 1;
        else high = middle;
    }
    return low;
}

int64_t coordinate_compression(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    int64_t sorted[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[i + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        sorted[i] = value;
    }
    if (capacity < n * 8 || (n > 0 && output == NULL)) return -2;
    qsort(sorted, n, sizeof(int64_t), compare_i64);
    int64_t ranks[MAX_N];
    int64_t rank = -1, previous = 0;
    for (size_t i = 0; i < n; ++i) {
        if (i == 0 || sorted[i] != previous) ++rank;
        ranks[i] = rank;
        previous = sorted[i];
    }
    for (size_t i = 0; i < n; ++i) {
        const size_t index = lower_bound_i64(sorted, n, input[i + 1]);
        put_i64_le(output, i * 8, ranks[index]);
    }
    return (int64_t)(n * 8);
}
