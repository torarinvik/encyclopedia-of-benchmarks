#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_INPUT_LENGTH 11

static int64_t mod_pow(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % MODULUS;
        base = (base * base) % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static int64_t step_denominator(int64_t coefficient, int64_t rho,
                                int64_t *numerator) {
    const int64_t factor = (rho + 1) % MODULUS;
    *numerator = (coefficient * factor) % MODULUS;
    return (1 + MODULUS - *numerator) % MODULUS;
}

static int divisors_are_nonzero(const int64_t *input, size_t count) {
    int64_t rho = 0;
    for (size_t index = 1; index < count; ++index) {
        int64_t numerator;
        const int64_t denominator = step_denominator(input[index + 1], rho, &numerator);
        if (denominator == 0) return 0;
        rho = (numerator * mod_pow(denominator, MODULUS - 2)) % MODULUS;
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

int64_t continued_fraction_forward_series_recurrence(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < 2 || count_value > 9) return -1;
    const size_t count = (size_t)count_value;
    if (length != count + 1) return -1;
    for (size_t index = 1; index <= count; ++index)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    if (!divisors_are_nonzero(input, count)) return -1;

    const size_t required = 8 * (count + 1);
    if (output == NULL || capacity < required) return -2;

    store_i64_le(output, 0, count_value);
    int64_t rho = 0;
    int64_t term = input[1];
    int64_t sum = term;
    store_i64_le(output, 8, sum);
    for (size_t index = 1; index < count; ++index) {
        int64_t numerator;
        const int64_t denominator = step_denominator(input[index + 1], rho, &numerator);
        rho = (numerator * mod_pow(denominator, MODULUS - 2)) % MODULUS;
        term = (rho * term) % MODULUS;
        sum = (sum + term) % MODULUS;
        store_i64_le(output, 8 * (index + 1), sum);
    }
    return (int64_t)required;
}
