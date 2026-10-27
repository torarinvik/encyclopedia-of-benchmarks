#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t best_fit_bin_packing(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 65) return -1;
    const int64_t n0 = input[0];
    if (n0 < 0 || n0 > 64 || length != 1 + (size_t)n0) return -1;
    const size_t n = (size_t)n0;
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 1 || input[i + 1] > 1000000) return -1;
    int64_t loads[64] = {0}, assignments[64] = {0};
    size_t bins = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t size = input[i + 1];
        size_t selected = bins;
        int64_t least_remaining = 1000001;
        for (size_t bin = 0; bin < bins; ++bin) {
            if (loads[bin] + size <= 1000000) {
                const int64_t remaining = 1000000 - loads[bin] - size;
                if (remaining < least_remaining) { least_remaining = remaining; selected = bin; }
            }
        }
        if (selected == bins) { loads[bins] = size; assignments[i] = (int64_t)bins; ++bins; }
        else { loads[selected] += size; assignments[i] = (int64_t)selected; }
    }
    const size_t bytes = 8 * (n + 1);
    if (output == NULL || capacity < bytes) return -2;
    put_i64(output, 0, (int64_t)bins);
    for (size_t i = 0; i < n; ++i) put_i64(output, i + 1, assignments[i]);
    return (int64_t)bytes;
}
