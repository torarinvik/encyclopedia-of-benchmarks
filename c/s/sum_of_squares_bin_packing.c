#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t sum_of_squares_bin_packing(const int64_t *input, size_t length,
                                   uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > 66) return -1;
    const int64_t capacity0 = input[0], n0 = input[1];
    if (capacity0 < 1 || capacity0 > 64 || n0 < 0 || n0 > 64 || length != 2 + (size_t)n0) return -1;
    const size_t n = (size_t)n0;
    for (size_t i = 0; i < n; ++i) if (input[i + 2] < 1 || input[i + 2] > capacity0) return -1;
    int64_t histogram[65] = {0}, loads[64] = {0}, assignments[64] = {0};
    size_t bins = 0;
    int64_t score = 0;
    for (size_t item = 0; item < n; ++item) {
        const int64_t size = input[item + 2];
        size_t selected = bins;
        int64_t best_score = INT64_MAX;
        for (size_t bin = 0; bin < bins; ++bin) {
            const int64_t from = loads[bin], to = from + size;
            if (to > capacity0) continue;
            int64_t candidate = score;
            if (from < capacity0) candidate += (histogram[from] - 1) * (histogram[from] - 1) - histogram[from] * histogram[from];
            if (to < capacity0) candidate += (histogram[to] + 1) * (histogram[to] + 1) - histogram[to] * histogram[to];
            if (candidate < best_score) { best_score = candidate; selected = bin; }
        }
        int64_t new_score = score;
        if (size < capacity0) new_score += (histogram[size] + 1) * (histogram[size] + 1) - histogram[size] * histogram[size];
        if (new_score < best_score) { best_score = new_score; selected = bins; }
        if (selected == bins) {
            loads[bins] = size;
            assignments[item] = (int64_t)bins;
            if (size < capacity0) ++histogram[size];
            ++bins;
        } else {
            const int64_t from = loads[selected], to = from + size;
            if (from < capacity0) --histogram[from];
            if (to < capacity0) ++histogram[to];
            loads[selected] = to;
            assignments[item] = (int64_t)selected;
        }
        score = best_score;
    }
    const size_t bytes = 8 * (n + 1);
    if (output == NULL || output_capacity < bytes) return -2;
    put_i64(output, 0, (int64_t)bins);
    for (size_t item = 0; item < n; ++item) put_i64(output, item + 1, assignments[item]);
    return (int64_t)bytes;
}
