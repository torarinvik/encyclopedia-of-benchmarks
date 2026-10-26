#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t first_fit_cardinality_bin_packing(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (!input || length < 4 || length > 35) return -1;
    int64_t n0 = input[0], limit0 = input[1], cap = input[2];
    if (n0 < 1 || n0 > 32 || limit0 < 1 || limit0 > 32 || cap < 1 || cap > 10000 || length != (size_t)n0 + 3) return -1;
    size_t n = (size_t)n0; int64_t limit = limit0;
    for (size_t i = 0; i < n; ++i) if (input[3 + i] < 1 || input[3 + i] > cap) return -1;
    int64_t loads[32] = {0}, used[32] = {0}, assignment[32] = {0};
    size_t bins = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t size = input[3 + i]; size_t b = 0;
        while (b < bins && (used[b] >= limit || loads[b] > cap - size)) ++b;
        if (b == bins) ++bins;
        loads[b] += size; ++used[b]; assignment[i] = (int64_t)b;
    }
    size_t bytes = 8 * (n + 1);
    if (!output || capacity < bytes) return -2;
    put_i64(output, 0, (int64_t)bins);
    for (size_t i = 0; i < n; ++i) put_i64(output, i + 1, assignment[i]);
    return (int64_t)bytes;
}
