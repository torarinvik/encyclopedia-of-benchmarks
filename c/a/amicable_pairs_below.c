/* Enumerate amicable pairs whose two members are below the exclusive limit. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LIMIT 8000

static void write_u32_le(uint8_t *output, size_t *position, int64_t value)
{
    const uint32_t encoded = (uint32_t)value;
    for (unsigned byte = 0; byte < 4; ++byte)
        output[(*position)++] = (uint8_t)(encoded >> (8U * byte));
}

int64_t amicable_pairs_below(const int64_t *values, size_t length, uint8_t *output,
                             size_t output_capacity)
{
    if (values == NULL || length != 1) return -1;
    if (values[0] < 1 || values[0] > MAX_LIMIT) return -1;
    const size_t limit = (size_t)values[0];
    int64_t divisor_sums[MAX_LIMIT] = {0};
    for (size_t divisor = 1; divisor < limit; ++divisor)
        for (size_t multiple = divisor * 2; multiple < limit; multiple += divisor)
            divisor_sums[multiple] += (int64_t)divisor;

    size_t pair_count = 0;
    for (size_t smaller = 2; smaller < limit; ++smaller) {
        const int64_t larger = divisor_sums[smaller];
        if (larger > (int64_t)smaller && larger < (int64_t)limit &&
            divisor_sums[(size_t)larger] == (int64_t)smaller)
            ++pair_count;
    }
    const size_t required = pair_count * 8;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;

    size_t position = 0;
    for (size_t smaller = 2; smaller < limit; ++smaller) {
        const int64_t larger = divisor_sums[smaller];
        if (larger > (int64_t)smaller && larger < (int64_t)limit &&
            divisor_sums[(size_t)larger] == (int64_t)smaller) {
            write_u32_le(output, &position, (int64_t)smaller);
            write_u32_le(output, &position, larger);
        }
    }
    return (int64_t)pair_count;
}
