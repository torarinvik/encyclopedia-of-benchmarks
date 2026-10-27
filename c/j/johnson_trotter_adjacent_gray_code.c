#include <stddef.h>
#include <stdint.h>

#define MAX_N 3
#define MAX_INPUT 2
#define MAX_OUTPUT_BYTES 144

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t johnson_trotter_adjacent_gray_code(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1 || length > MAX_INPUT || input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    size_t permutation_count = 1;
    for (size_t value = 2; value <= n; ++value) permutation_count *= value;
    const size_t output_bytes = 8 * n * permutation_count;
    if (output == NULL || capacity < output_bytes) return -2;
    int64_t permutation[MAX_N], direction[MAX_N + 1];
    for (size_t index = 0; index < n; ++index) { permutation[index] = (int64_t)index + 1; direction[index + 1] = -1; }
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    size_t rows = 0;
    for (;;) {
        for (size_t index = 0; index < n; ++index) store_i64_le(staged, 8 * (rows * n + index), permutation[index]);
        ++rows;
        int64_t largest_mobile = 0;
        size_t mobile_position = n;
        for (size_t position = 0; position < n; ++position) {
            const int64_t value = permutation[position];
            const int64_t neighbor = (int64_t)position + direction[value];
            if (neighbor >= 0 && neighbor < (int64_t)n && value > permutation[(size_t)neighbor] && value > largest_mobile) {
                largest_mobile = value;
                mobile_position = position;
            }
        }
        if (mobile_position == n) break;
        const size_t neighbor = (size_t)((int64_t)mobile_position + direction[largest_mobile]);
        const int64_t temporary = permutation[mobile_position];
        permutation[mobile_position] = permutation[neighbor];
        permutation[neighbor] = temporary;
        for (int64_t value = largest_mobile + 1; value <= (int64_t)n; ++value) direction[value] = -direction[value];
    }
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
