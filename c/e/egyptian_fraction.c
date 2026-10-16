/* Return the greedy Egyptian-fraction unit denominators as little-endian i32s. */
#include <stddef.h>
#include <stdint.h>

int64_t egyptian_fraction(const int64_t *input, size_t length,
                          uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 2) return -1;
    int64_t numerator = input[0], denominator = input[1];
    if (numerator < 0 || denominator < 1 || denominator > 10 || numerator > denominator) return -1;

    uint32_t terms[10];
    size_t count = 0;
    while (numerator != 0) {
        int64_t unit_denominator = denominator / numerator;
        if (denominator % numerator != 0) ++unit_denominator;
        terms[count++] = (uint32_t)unit_denominator;
        numerator = numerator * unit_denominator - denominator;
        denominator = denominator * unit_denominator;
    }
    const size_t required = count * 4;
    if (output_capacity < required || (required > 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index) {
        const uint32_t value = terms[index];
        for (size_t byte = 0; byte < 4; ++byte) output[index * 4 + byte] = (uint8_t)(value >> (8 * byte));
    }
    return (int64_t)required;
}
