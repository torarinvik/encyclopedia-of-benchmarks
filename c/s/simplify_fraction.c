#include <stddef.h>
#include <stdint.h>

#define MAX_ABS_COMPONENT INT64_C(1000000)
#define OUTPUT_BYTES 16u

static uint64_t magnitude(int64_t value) {
    return value < 0 ? (uint64_t)(-value) : (uint64_t)value;
}

static uint64_t gcd_positive(uint64_t a, uint64_t b) {
    while (b != 0u) {
        const uint64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8u; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t simplify_fraction(const int64_t *input, size_t input_length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || input_length != 2u) return -1;
    const int64_t numerator = input[0], denominator = input[1];
    if (numerator < -MAX_ABS_COMPONENT || numerator > MAX_ABS_COMPONENT ||
        denominator < -MAX_ABS_COMPONENT || denominator > MAX_ABS_COMPONENT || denominator == 0) return -1;
    const uint64_t divisor = gcd_positive(magnitude(numerator), magnitude(denominator));
    const int64_t reduced_numerator = numerator / (int64_t)divisor;
    const int64_t reduced_denominator = denominator / (int64_t)divisor;
    uint8_t staged[OUTPUT_BYTES];
    put_i64_le(staged, 0u, reduced_numerator);
    put_i64_le(staged, 8u, reduced_denominator);
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;
    for (size_t i = 0; i < OUTPUT_BYTES; ++i) output[i] = staged[i];
    return (int64_t)OUTPUT_BYTES;
}
