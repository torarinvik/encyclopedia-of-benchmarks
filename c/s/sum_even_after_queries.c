/* Apply each point update, then emit the running sum of even values. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NUMBERS 1000
#define MAX_QUERIES 1000

int64_t sum_even_after_queries(const int64_t *values, size_t length,
                               uint8_t *output, size_t output_capacity)
{
    if (length < 5 || length > 2 + MAX_NUMBERS + 2 * MAX_QUERIES || values == NULL) return -1;
    if (values[0] < 1 || values[0] > MAX_NUMBERS || values[1] < 1 || values[1] > MAX_QUERIES) return -1;
    const size_t number_count = (size_t)values[0];
    const size_t query_count = (size_t)values[1];
    if (length != 2 + number_count + 2 * query_count) return -1;

    int64_t working[MAX_NUMBERS];
    int64_t even_sum = 0;
    for (size_t index = 0; index < number_count; ++index) {
        const int64_t value = values[2 + index];
        if (value < 1 || value > 1000) return -1;
        working[index] = value;
        if (value % 2 == 0) even_sum += value;
    }
    for (size_t query = 0; query < query_count; ++query) {
        const size_t offset = 2 + number_count + 2 * query;
        if (values[offset] < -1000 || values[offset] > 1000 ||
            values[offset + 1] < 0 || values[offset + 1] >= (int64_t)number_count) return -1;
    }
    const size_t output_bytes = query_count * 4;
    if (output_capacity < output_bytes || output == NULL) return -2;

    for (size_t query = 0; query < query_count; ++query) {
        const size_t offset = 2 + number_count + 2 * query;
        const int64_t delta = values[offset];
        const size_t index = (size_t)values[offset + 1];
        if (working[index] % 2 == 0) even_sum -= working[index];
        working[index] += delta;
        if (working[index] % 2 == 0) even_sum += working[index];
        const uint32_t bits = (uint32_t)(int32_t)even_sum;
        for (size_t byte = 0; byte < 4; ++byte)
            output[query * 4 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)query_count;
}
