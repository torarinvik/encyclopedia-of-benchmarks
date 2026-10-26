#include <stddef.h>
#include <stdint.h>

int64_t directed_perfect_phylogeny(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (!input || length < 3 || length > 146) return -1;
    int64_t n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 12 || m0 < 1 || m0 > 12 || length != 2 + (size_t)n0 * (size_t)m0) return -1;
    size_t n = (size_t)n0, m = (size_t)m0;
    uint16_t sets[12] = {0};
    for (size_t row = 0; row < n; ++row) for (size_t col = 0; col < m; ++col) {
        int64_t bit = input[2 + row * m + col];
        if (bit != 0 && bit != 1) return -1;
        if (bit) sets[col] |= (uint16_t)(1u << row);
    }
    int64_t possible = 1;
    for (size_t a = 0; a < m; ++a) for (size_t b = a + 1; b < m; ++b) {
        uint16_t intersection = sets[a] & sets[b];
        if (intersection != 0 && intersection != sets[a] && intersection != sets[b]) possible = 0;
    }
    if (!output || capacity < 8) return -2;
    uint64_t word = (uint64_t)possible;
    for (size_t b = 0; b < 8; ++b) output[b] = (uint8_t)(word >> (8 * b));
    return 8;
}
