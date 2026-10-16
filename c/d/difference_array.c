#include <stddef.h>
#include <stdint.h>

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t difference_array(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return -1;
    const int64_t raw_n = input[0], raw_q = input[1];
    if (raw_n < 1 || raw_n > 64 || raw_q < 0 || raw_q > 64) return -1;
    const size_t n = (size_t)raw_n, q = (size_t)raw_q;
    if (length != 2 + n + 3 * q) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2 + i] < -1000000 || input[2 + i] > 1000000) return -1;
    for (size_t u = 0; u < q; ++u) {
        const size_t base = 2 + n + 3 * u;
        if (input[base] < 0 || input[base] >= raw_n || input[base + 1] < input[base] || input[base + 1] >= raw_n ||
            input[base + 2] < -1000000 || input[base + 2] > 1000000) return -1;
    }
    const size_t bytes = n * 8;
    if (output == NULL || capacity < bytes) return -2;
    int64_t diff[65] = {0};
    diff[0] = input[2];
    for (size_t i = 1; i < n; ++i) diff[i] = input[2 + i] - input[2 + i - 1];
    for (size_t u = 0; u < q; ++u) {
        const size_t base = 2 + n + 3 * u;
        const size_t left = (size_t)input[base], right = (size_t)input[base + 1];
        const int64_t delta = input[base + 2];
        diff[left] += delta;
        diff[right + 1] -= delta;
    }
    int64_t current = diff[0];
    put_i64_le(output, 0, current);
    for (size_t i = 1; i < n; ++i) { current += diff[i]; put_i64_le(output, i * 8, current); }
    return (int64_t)bytes;
}
