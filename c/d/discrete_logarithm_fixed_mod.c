#include <stddef.h>
#include <stdint.h>

int64_t discrete_logarithm_fixed_mod(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (!input || length < 3 || length > 259) return -1;
    if (input[0] < 2 || input[0] > 4093 || input[1] < 1 ||
        input[1] >= input[0] || input[2] < 1 || input[2] > 256) return -1;
    int p = (int)input[0], g = (int)input[1], n = (int)input[2];
    if (length != (size_t)(n + 3)) return -1;
    for (int d = 2; d * d <= p; ++d) if (p % d == 0) return -1;
    for (int i = 0; i < n; ++i) if (input[3+i] < 1 || input[3+i] >= p) return -1;
    int16_t table[4094];
    for (int i = 0; i < p; ++i) table[i] = -1;
    int residue = 1;
    for (int exponent = 0; exponent < p-1; ++exponent) {
        if (table[residue] != -1) return -1;
        table[residue] = (int16_t)exponent;
        residue = residue * g % p;
    }
    if (residue != 1) return -1;
    if (!output || capacity < (size_t)(8*n)) return -2;
    for (int i = 0; i < n; ++i) {
        uint64_t value = (uint64_t)table[input[3+i]];
        for (int byte = 0; byte < 8; ++byte)
            output[8*i+byte] = (uint8_t)(value >> (8*byte));
    }
    return 8*n;
}
