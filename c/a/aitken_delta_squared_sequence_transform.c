#include <stddef.h>
#include <stdint.h>

#define MAX_TERMS 64
#define MAX_WORDS 66
#define VALUE_LIMIT 1000000

static uint64_t aitken_gcd(uint64_t left, uint64_t right)
{
    while (right != 0) {
        const uint64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static void aitken_store_i64(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t aitken_delta_squared_sequence_transform(const int64_t *values,
                                                size_t length,
                                                uint8_t *output,
                                                size_t output_capacity)
{
    if (values == NULL || length < 3 || length > MAX_WORDS) return -1;
    const int64_t term_count_value = values[0];
    if (term_count_value < 2 || term_count_value > MAX_TERMS ||
        length != (size_t)term_count_value + 1) return -1;
    const size_t term_count = (size_t)term_count_value;
    for (size_t index = 0; index < term_count; ++index)
        if (values[index + 1] < -VALUE_LIMIT || values[index + 1] > VALUE_LIMIT)
            return -1;

    const size_t output_length = 16 * (term_count - 2);
    if (output == NULL || output_capacity < output_length) return -2;

    for (size_t index = 0; index + 2 < term_count; ++index) {
        const int64_t first = values[index + 1];
        const int64_t middle = values[index + 2];
        const int64_t last = values[index + 3];
        int64_t numerator = first * last - middle * middle;
        int64_t denominator = first - 2 * middle + last;
        if (denominator == 0) {
            if (first == middle && middle == last) {
                numerator = first;
                denominator = 1;
            } else {
                numerator = 0;
            }
        } else {
            if (denominator < 0) {
                numerator = -numerator;
                denominator = -denominator;
            }
            const uint64_t magnitude = numerator < 0 ? (uint64_t)(-numerator) : (uint64_t)numerator;
            const uint64_t divisor = aitken_gcd(magnitude, (uint64_t)denominator);
            numerator /= (int64_t)divisor;
            denominator /= (int64_t)divisor;
        }
        const size_t offset = index * 16;
        aitken_store_i64(output, offset, numerator);
        aitken_store_i64(output, offset + 8, denominator);
    }
    return (int64_t)output_length;
}
