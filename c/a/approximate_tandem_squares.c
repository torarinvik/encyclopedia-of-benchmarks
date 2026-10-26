#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t approximate_tandem_squares(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 34) return -1;
    int64_t n0 = input[0], budget = input[1];
    if (n0 < 2 || n0 > 32 || budget < 0 || budget > 8 || length != (size_t)n0 + 2) return -1;
    size_t n = (size_t)n0;
    for (size_t i = 0; i < n; ++i) if (input[2 + i] < 0 || input[2 + i] > 3) return -1;
    int64_t records[256][3];
    size_t count = 0;
    for (size_t start = 0; start < n; ++start) {
        for (size_t period = 1; 2 * period <= n - start; ++period) {
            int64_t mismatches = 0;
            for (size_t i = 0; i < period; ++i)
                mismatches += input[2 + start + i] != input[2 + start + period + i];
            if (mismatches <= budget) {
                records[count][0] = (int64_t)start;
                records[count][1] = (int64_t)period;
                records[count][2] = mismatches;
                ++count;
            }
        }
    }
    size_t bytes = 8 * (1 + 3 * count);
    if (!output || capacity < bytes) return -2;
    put_i64(output, 0, (int64_t)count);
    for (size_t i = 0; i < count; ++i)
        for (size_t j = 0; j < 3; ++j) put_i64(output, 1 + 3 * i + j, records[i][j]);
    return (int64_t)bytes;
}
