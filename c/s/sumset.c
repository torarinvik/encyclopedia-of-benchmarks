/* Emit the sorted unique pairwise sums of two bounded integer sets. */
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define MIN_SUM (-2000)
#define MAX_SUM 2000
#define SUM_COUNT 4001
#define MAX_SET_SIZE 64

static size_t decimal_width(uint64_t value)
{
    size_t width = 1;
    while (value >= 10) { value /= 10; ++width; }
    return width;
}

static size_t append_signed_decimal(uint8_t *output, size_t position, int64_t value)
{
    if (value < 0) { output[position++] = '-'; value = -value; }
    uint8_t digits[20];
    size_t count = 0;
    do { digits[count++] = (uint8_t)((uint64_t)value % 10); value /= 10; } while (value != 0);
    while (count > 0) output[position++] = (uint8_t)('0' + digits[--count]);
    return position;
}

int64_t sumset(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2) return -1;
    const int64_t count_a = values[0], count_b = values[1];
    if (count_a < 0 || count_a > MAX_SET_SIZE || count_b < 0 || count_b > MAX_SET_SIZE ||
        length != 2 + (size_t)count_a + (size_t)count_b) return -1;
    bool present[SUM_COUNT] = {false};
    for (size_t index_a = 0; index_a < (size_t)count_a; ++index_a)
        if (values[2 + index_a] < -1000 || values[2 + index_a] > 1000) return -1;
    for (size_t index_b = 0; index_b < (size_t)count_b; ++index_b) {
        const int64_t right = values[2 + (size_t)count_a + index_b];
        if (right < -1000 || right > 1000) return -1;
    }
    for (size_t index_a = 0; index_a < (size_t)count_a; ++index_a) {
        const int64_t left = values[2 + index_a];
        for (size_t index_b = 0; index_b < (size_t)count_b; ++index_b) {
            const int64_t right = values[2 + (size_t)count_a + index_b];
            const int64_t sum = left + right;
            present[sum - MIN_SUM] = true;
        }
    }
    size_t needed = 0;
    for (int64_t sum = MIN_SUM; sum <= MAX_SUM; ++sum) {
        if (present[sum - MIN_SUM])
            needed += (sum < 0 ? 1 : 0) + decimal_width((uint64_t)(sum < 0 ? -sum : sum)) + 1;
    }
    if (needed == 0) return 0;
    if (output == NULL || output_capacity < needed) return -2;
    size_t position = 0;
    for (int64_t sum = MIN_SUM; sum <= MAX_SUM; ++sum) {
        if (!present[sum - MIN_SUM]) continue;
        position = append_signed_decimal(output, position, sum);
        output[position++] = '\n';
    }
    return (int64_t)position;
}
