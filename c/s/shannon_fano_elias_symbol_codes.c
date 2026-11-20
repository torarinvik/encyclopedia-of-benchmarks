#include <stddef.h>
#include <stdint.h>

int64_t shannon_fano_elias_symbol_codes(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 10) return -1;
    int64_t raw_n = input[0];
    if (raw_n < 1 || raw_n > 8 || length != (size_t)(raw_n + 1)) return -1;
    size_t n = (size_t)raw_n;
    int64_t total = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t weight = input[1 + i];
        if (weight < 1 || weight > 15) return -1;
        total += weight;
    }
    if (total > 120) return -1;

    uint8_t staged[17] = {0};
    staged[0] = (uint8_t)n;
    int64_t prefix = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t weight = input[1 + i];
        unsigned bits = 1;
        while (((int64_t)1 << (bits - 1)) * weight < total) ++bits;
        int64_t numerator = (2 * prefix + weight) * ((int64_t)1 << (bits - 1));
        uint8_t code = (uint8_t)(numerator / total);
        staged[1 + 2 * i] = (uint8_t)bits;
        staged[2 + 2 * i] = (uint8_t)(code << (8 - bits));
        prefix += weight;
    }
    size_t needed = 1 + 2 * n;
    if (output == NULL || capacity < needed) return -2;
    for (size_t i = 0; i < needed; ++i) output[i] = staged[i];
    return (int64_t)needed;
}
