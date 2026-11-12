#include <stddef.h>
#include <stdint.h>

#define PREFIX_MODULUS INT64_C(998244353)
#define PREFIX_MAX_T 16
#define PREFIX_MAX_N 128
#define PREFIX_MAX_INPUT 34

int64_t prefix_sum_of_binomial_coefficient(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > PREFIX_MAX_INPUT) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > PREFIX_MAX_T) return -1;
    const size_t count = (size_t)count_value;
    if (length != 1 + 2 * count) return -1;
    int64_t n[PREFIX_MAX_T], k[PREFIX_MAX_T];
    for (size_t query = 0; query < count; ++query) {
        n[query] = input[1 + 2 * query];
        k[query] = input[2 + 2 * query];
        if (n[query] < 0 || n[query] > PREFIX_MAX_N ||
            k[query] < 0 || k[query] > n[query]) return -1;
    }
    const size_t output_length = 4 * count;
    if (output == NULL || capacity < output_length) return -2;

    int64_t inverse[PREFIX_MAX_N + 1] = {0};
    inverse[1] = 1;
    for (size_t value = 2; value <= PREFIX_MAX_N; ++value) {
        inverse[value] = PREFIX_MODULUS -
            (PREFIX_MODULUS / (int64_t)value) * inverse[PREFIX_MODULUS % value]
                % PREFIX_MODULUS;
    }
    for (size_t query = 0; query < count; ++query) {
        int64_t coefficient = 1;
        int64_t prefix = 1;
        for (int64_t index = 0; index < k[query]; ++index) {
            coefficient = coefficient * (n[query] - index) % PREFIX_MODULUS;
            coefficient = coefficient * inverse[index + 1] % PREFIX_MODULUS;
            prefix = (prefix + coefficient) % PREFIX_MODULUS;
        }
        const uint32_t residue = (uint32_t)prefix;
        const size_t offset = 4 * query;
        output[offset] = (uint8_t)residue;
        output[offset + 1] = (uint8_t)(residue >> 8);
        output[offset + 2] = (uint8_t)(residue >> 16);
        output[offset + 3] = (uint8_t)(residue >> 24);
    }
    return (int64_t)output_length;
}
