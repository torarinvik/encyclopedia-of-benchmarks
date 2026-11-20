#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_INPUT_LENGTH 35

static int64_t mod_pow(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static int64_t reduce_difference(int64_t left, int64_t right) {
    return (left + MODULUS - right) % MODULUS;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t miller_backward_recurrence_normalization(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t levels_value = input[0];
    if (levels_value < 1 || levels_value > 8) return -1;
    const size_t levels = (size_t)levels_value;
    if (length != 4 * levels + 2) return -1;
    for (size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    for (size_t level = 1; level <= levels; ++level)
        if (input[3 * level] == 0) return -1;

    int64_t trial[10] = {0};
    trial[levels] = 1;
    trial[levels + 1] = 0;
    for (size_t level = levels; level > 0; --level) {
        const int64_t a_value = input[3 * level - 2];
        const int64_t b_value = input[3 * level - 1];
        const int64_t c_value = input[3 * level];
        const int64_t positive = b_value * trial[level] % MODULUS;
        const int64_t negative = a_value * trial[level + 1] % MODULUS;
        const int64_t numerator = reduce_difference(positive, negative);
        trial[level - 1] = numerator * mod_pow(c_value, MODULUS - 2) % MODULUS;
    }
    const size_t lambda_start = 3 * levels + 1;
    int64_t normalizer = 0;
    for (size_t index = 0; index <= levels; ++index)
        normalizer = (normalizer + input[lambda_start + index] * trial[index]) % MODULUS;
    if (normalizer == 0) return -1;
    const int64_t scale = mod_pow(normalizer, MODULUS - 2);
    const size_t required = 8 * (levels + 2);
    if (output == NULL || capacity < required) return -2;

    store_i64_le(output, 0, levels_value);
    for (size_t index = 0; index <= levels; ++index)
        store_i64_le(output, 8 * (index + 1), trial[index] * scale % MODULUS);
    return (int64_t)required;
}
