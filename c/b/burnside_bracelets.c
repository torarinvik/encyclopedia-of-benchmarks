#include <stddef.h>
#include <stdint.h>

#define MAX_N 10
#define MAX_INPUT_VALUES 3
#define OUTPUT_BYTES 8

static size_t cycle_count(size_t n, size_t shift, int reflection) {
    int seen[MAX_N] = {0};
    size_t cycles = 0;
    for (size_t start = 0; start < n; ++start) {
        if (seen[start]) continue;
        ++cycles;
        size_t position = start;
        while (!seen[position]) {
            seen[position] = 1;
            position = reflection ? (shift + n - position) % n
                                 : (position + shift) % n;
        }
    }
    return cycles;
}

static int64_t colorings_fixed_by(size_t n, size_t shift, int reflection,
                                  int64_t colors) {
    const size_t cycles = cycle_count(n, shift, reflection);
    int64_t result = 1;
    for (size_t cycle = 0; cycle < cycles; ++cycle) result *= colors;
    return result;
}

static void store_i64_le(uint8_t *output, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < OUTPUT_BYTES; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t burnside_bracelets(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    if (length != 2) return -1;
    const int64_t n_value = input[0];
    const int64_t colors = input[1];
    if (n_value < 1 || n_value > MAX_N || colors < 0 || colors > 3) return -1;
    const size_t n = (size_t)n_value;

    int64_t fixed_sum = 0;
    for (size_t shift = 0; shift < n; ++shift) {
        fixed_sum += colorings_fixed_by(n, shift, 0, colors);
        fixed_sum += colorings_fixed_by(n, shift, 1, colors);
    }
    const int64_t answer = fixed_sum / (int64_t)(2 * n);
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;
    store_i64_le(output, answer);
    return OUTPUT_BYTES;
}
