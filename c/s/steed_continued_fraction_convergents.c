#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_INPUT_LENGTH 19

static int64_t mod_pow(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static int divisors_are_nonzero(const int64_t *input, size_t levels) {
    if (input[2] == 0) return 0;
    int64_t d_value = mod_pow(input[2], MODULUS - 2);
    for (size_t level = 2; level <= levels; ++level) {
        const int64_t denominator =
            (d_value * input[2 * level + 1] + input[2 * level]) % MODULUS;
        if (denominator == 0) return 0;
        d_value = mod_pow(denominator, MODULUS - 2);
    }
    return 1;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t steed_continued_fraction_convergents(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t levels_value = input[0];
    if (levels_value < 1 || levels_value > 8) return -1;
    const size_t levels = (size_t)levels_value;
    if (length != 2 + 2 * levels) return -1;
    for (size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    if (!divisors_are_nonzero(input, levels)) return -1;

    const size_t required = 8 * (levels + 2);
    if (output == NULL || capacity < required) return -2;
    store_i64_le(output, 0, levels_value + 1);

    int64_t current = input[1];
    store_i64_le(output, 8, current);
    int64_t d_value = mod_pow(input[2], MODULUS - 2);
    int64_t delta = input[3] * d_value % MODULUS;
    current = (current + delta) % MODULUS;
    store_i64_le(output, 16, current);
    for (size_t level = 2; level <= levels; ++level) {
        const int64_t b_value = input[2 * level];
        const int64_t a_value = input[2 * level + 1];
        const int64_t denominator = (d_value * a_value + b_value) % MODULUS;
        d_value = mod_pow(denominator, MODULUS - 2);
        const int64_t factor = (b_value * d_value + MODULUS - 1) % MODULUS;
        delta = factor * delta % MODULUS;
        current = (current + delta) % MODULUS;
        store_i64_le(output, 8 * (level + 1), current);
    }
    return (int64_t)required;
}
