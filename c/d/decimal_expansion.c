#include <stddef.h>
#include <stdint.h>

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

int64_t decimal_expansion(const int64_t *values, size_t length,
                          uint8_t *output, size_t capacity)
{
    if (values == NULL || length != 3) return -1;
    const int64_t numerator = values[0];
    const int64_t denominator = values[1];
    const int64_t base = values[2];
    if (numerator < 0 || denominator < 1 || denominator > 256 ||
        numerator > denominator || base < 2 || base > 10) return -1;

    uint8_t digits[255];
    int64_t first_seen[256];
    for (size_t index = 0; index < 256; ++index) first_seen[index] = -1;
    size_t digit_count = 0;
    int64_t cycle_start = -1;
    int64_t remainder = numerator;
    while (remainder != 0 && numerator != denominator) {
        const size_t remainder_index = (size_t)remainder;
        if (first_seen[remainder_index] >= 0) {
            cycle_start = first_seen[remainder_index];
            break;
        }
        first_seen[remainder_index] = (int64_t)digit_count;
        const int64_t scaled = remainder * base;
        digits[digit_count++] = (uint8_t)(scaled / denominator);
        remainder = scaled % denominator;
    }

    const size_t required = 24 + digit_count;
    if (output == NULL || capacity < required) return -2;
    const int64_t integer_part = numerator == denominator ? 1 : 0;
    write_i64_le(output, 0, integer_part);
    write_i64_le(output, 8, (int64_t)digit_count);
    write_i64_le(output, 16, cycle_start);
    for (size_t index = 0; index < digit_count; ++index) output[24 + index] = digits[index];
    return (int64_t)required;
}
