#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t bounded_space_best_fit_bin_packing(const int64_t *input, size_t length,
                                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > 65) return -1;
    const int64_t n0 = input[0];
    if (n0 < 0 || n0 > 64 || length != 1 + (size_t)n0) return -1;
    const size_t n = (size_t)n0;
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 1 || input[i + 1] > 1000000) return -1;
    int64_t loads[64] = {0}, assignments[64] = {0};
    uint8_t open[64] = {0};
    size_t bins = 0;
    for (size_t item = 0; item < n; ++item) {
        const int64_t size = input[item + 1];
        size_t selected = bins;
        int64_t least_remaining = 1000001;
        for (size_t bin = 0; bin < bins; ++bin) {
            if (open[bin] && loads[bin] + size <= 1000000) {
                const int64_t remaining = 1000000 - loads[bin] - size;
                if (remaining < least_remaining) { least_remaining = remaining; selected = bin; }
            }
        }
        if (selected == bins) { loads[bins] = size; open[bins] = size < 1000000; assignments[item] = (int64_t)bins; ++bins; }
        else { loads[selected] += size; assignments[item] = (int64_t)selected; if (loads[selected] == 1000000) open[selected] = 0; }
        size_t partial_open = 0;
        for (size_t bin = 0; bin < bins; ++bin) if (open[bin]) ++partial_open;
        while (partial_open > 2) {
            size_t weakest = bins;
            for (size_t bin = 0; bin < bins; ++bin) {
                if (open[bin] && (weakest == bins || loads[bin] < loads[weakest]
                    || (loads[bin] == loads[weakest] && bin > weakest))) weakest = bin;
            }
            open[weakest] = 0;
            --partial_open;
        }
    }
    const size_t bytes = 8 * (n + 1);
    if (output == NULL || output_capacity < bytes) return -2;
    put_i64(output, 0, (int64_t)bins);
    for (size_t item = 0; item < n; ++item) put_i64(output, item + 1, assignments[item]);
    return (int64_t)bytes;
}
