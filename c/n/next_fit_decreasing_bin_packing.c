#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t next_fit_decreasing_bin_packing(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 65) return -1;
    const int64_t n0 = input[0];
    if (n0 < 0 || n0 > 64 || length != 1 + (size_t)n0) return -1;
    const size_t n = (size_t)n0;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 1 || input[i + 1] > 1000000) return -1;

    size_t order[64];
    int64_t assignments[64] = {0};
    for (size_t i = 0; i < n; ++i) order[i] = i;
    /* Stable descending insertion sort: equal sizes retain input order. */
    for (size_t i = 1; i < n; ++i) {
        const size_t item = order[i];
        size_t j = i;
        while (j > 0 && input[order[j - 1] + 1] < input[item + 1]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = item;
    }

    int64_t bins = 0, remaining = 0;
    for (size_t rank = 0; rank < n; ++rank) {
        const size_t item = order[rank];
        const int64_t size = input[item + 1];
        if (bins == 0 || size > remaining) {
            assignments[item] = bins++;
            remaining = 1000000 - size;
        } else {
            assignments[item] = bins - 1;
            remaining -= size;
        }
    }

    const size_t bytes = 8 * (n + 1);
    if (output == NULL || capacity < bytes) return -2;
    put_i64(output, 0, bins);
    for (size_t i = 0; i < n; ++i) put_i64(output, i + 1, assignments[i]);
    return (int64_t)bytes;
}
