#include <stddef.h>
#include <stdint.h>

#define MAX_TRACE_VALUES 256
#define MAX_KEY INT64_C(1000000000)

static void positions(int64_t value, unsigned *first, unsigned *second)
{
    *first = (unsigned)((value * 17 + 3) % 64);
    *second = (unsigned)((value * 31 + 7) % 64);
}

int64_t bloom_filter(const int64_t *trace, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    if (length > MAX_TRACE_VALUES || length % 2 != 0 || (length != 0 && trace == NULL)) return -1;
    size_t query_count = 0;
    for (size_t index = 0; index < length; index += 2) {
        const int64_t operation = trace[index];
        const int64_t key = trace[index + 1];
        if ((operation != 1 && operation != 2) || key < 0 || key > MAX_KEY) return -1;
        if (operation == 2) ++query_count;
    }
    if (output_capacity < query_count || (query_count != 0 && output == NULL)) return -2;

    uint64_t bits = 0;
    size_t written = 0;
    for (size_t index = 0; index < length; index += 2) {
        unsigned first, second;
        positions(trace[index + 1], &first, &second);
        const uint64_t first_mask = UINT64_C(1) << first;
        const uint64_t second_mask = UINT64_C(1) << second;
        if (trace[index] == 1) {
            bits |= first_mask | second_mask;
        } else {
            output[written++] = (uint8_t)((bits & first_mask) != 0 && (bits & second_mask) != 0);
        }
    }
    return (int64_t)written;
}
