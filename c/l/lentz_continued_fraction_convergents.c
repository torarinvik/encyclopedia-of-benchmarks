#include <stddef.h>
#include <stdint.h>

enum { MAX_TERMS = 8, MAX_INPUT_LENGTH = 19 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t normalize(int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static int64_t power(int64_t base, int64_t exponent) {
    int64_t result = 1;
    base = normalize(base);
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t lentz_continued_fraction_convergents(const int64_t *input, size_t length,
                                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_TERMS) return -1;
    const size_t count = (size_t)count_value;
    if (length != 2 + 2 * count) return -1;
    for (size_t i = 1; i < length; ++i)
        if (input[i] < 0 || input[i] >= MODULUS) return -1;
    int64_t value = input[1];
    if (value == 0) return -1;
    int64_t c_ratio = value;
    int64_t d_ratio = 0;
    int64_t trace[MAX_TERMS + 2] = {0};
    trace[0] = value;
    for (size_t index = 0; index < count; ++index) {
        const int64_t numerator = input[2 + 2 * index];
        const int64_t denominator = input[3 + 2 * index];
        const int64_t d_denominator = normalize(denominator + numerator * d_ratio);
        if (d_denominator == 0 || c_ratio == 0) return -1;
        const int64_t c_value = normalize(denominator
            + numerator * power(c_ratio, MODULUS - 2));
        if (c_value == 0) return -1;
        d_ratio = power(d_denominator, MODULUS - 2);
        value = value * c_value % MODULUS * d_ratio % MODULUS;
        c_ratio = c_value;
        trace[index + 1] = value;
    }
    const size_t output_bytes = 8 * (count + 2);
    if (output == NULL || capacity < output_bytes) return -2;
    store_i64_le(output, 0, (int64_t)(count + 1));
    for (size_t i = 0; i <= count; ++i)
        store_i64_le(output, 8 * (i + 1), trace[i]);
    return (int64_t)output_bytes;
}
