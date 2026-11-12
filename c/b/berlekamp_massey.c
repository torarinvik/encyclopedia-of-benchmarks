#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_ORDER 8
#define MAX_TERMS (2 * MAX_ORDER)
#define MAX_INPUT_VALUES (1 + MAX_TERMS + 1)

static int64_t normalize(int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static int64_t multiply(int64_t left, int64_t right) {
    return (left * right) % MODULUS;
}

static int64_t power(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = multiply(result, base);
        base = multiply(base, base);
        exponent >>= 1;
    }
    return result;
}

static void store_i64_le(uint8_t *output, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

static int infer_recurrence(const int64_t *sequence, int term_count,
                            int64_t *coefficients) {
    int64_t current[MAX_TERMS + 1] = {0};
    int64_t previous[MAX_TERMS + 1] = {0};
    int64_t old[MAX_TERMS + 1] = {0};
    int current_length = 0;
    int previous_length = 0;
    int last_index = -1;
    int64_t last_discrepancy = 0;

    for (int index = 0; index < term_count; ++index) {
        int64_t predicted = 0;
        for (int lag = 0; lag < current_length && lag < index; ++lag)
            predicted = normalize(predicted + multiply(sequence[index - lag - 1], current[lag]));
        const int64_t discrepancy = normalize(sequence[index] - predicted);
        if (discrepancy == 0) continue;

        if (last_index < 0) {
            last_index = index;
            last_discrepancy = discrepancy;
            current_length = index + 1;
            for (int lag = 0; lag < current_length; ++lag) current[lag] = 0;
            continue;
        }

        for (int lag = 0; lag < current_length; ++lag) old[lag] = current[lag];
        const int old_length = current_length;
        const int64_t scale = multiply(discrepancy,
            power(last_discrepancy, MODULUS - 2));
        const int shift = index - last_index;
        const int needed_length = previous_length + shift;
        if (current_length < needed_length) {
            for (int lag = current_length; lag < needed_length; ++lag) current[lag] = 0;
            current_length = needed_length;
        }
        current[shift - 1] = normalize(current[shift - 1] + scale);
        for (int lag = 0; lag < previous_length; ++lag)
            current[shift + lag] = normalize(
                current[shift + lag] - multiply(scale, previous[lag]));

        if (old_length - index < previous_length - last_index) {
            for (int lag = 0; lag < old_length; ++lag) previous[lag] = old[lag];
            previous_length = old_length;
            last_index = index;
            last_discrepancy = discrepancy;
        }
    }

    for (int lag = 0; lag < current_length; ++lag) coefficients[lag] = current[lag];
    return current_length;
}

int64_t berlekamp_massey(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t bound_value = input[0];
    if (bound_value < 1 || bound_value > MAX_ORDER) return -1;
    const int bound = (int)bound_value;
    const int term_count = 2 * bound;
    if (length != (size_t)(1 + term_count)) return -1;

    int64_t sequence[MAX_TERMS];
    for (int index = 0; index < term_count; ++index) {
        const int64_t value = input[1 + index];
        if (value < 0 || value >= MODULUS) return -1;
        sequence[index] = value;
    }

    int64_t coefficients[MAX_TERMS + 1] = {0};
    const int order = infer_recurrence(sequence, term_count, coefficients);
    if (order > bound) return -1;
    const size_t output_bytes = 8 * (size_t)(order + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    store_i64_le(output, order);
    for (int lag = 0; lag < order; ++lag)
        store_i64_le(output + 8 * (size_t)(lag + 1), coefficients[lag]);
    return (int64_t)output_bytes;
}
