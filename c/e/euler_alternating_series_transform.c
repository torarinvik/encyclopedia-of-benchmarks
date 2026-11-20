#include <stddef.h>
#include <stdint.h>

#define MAX_TERMS 16
#define MAX_WORDS 18
#define VALUE_LIMIT 1000000
#define OUTPUT_BYTES 16

static uint64_t euler_gcd(uint64_t left, uint64_t right)
{
    while (right != 0) {
        const uint64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static void euler_store_i64(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t euler_alternating_series_transform(const int64_t *values,
                                           size_t length,
                                           uint8_t *output,
                                           size_t output_capacity)
{
    if (values == NULL || length < 2 || length > MAX_WORDS) return -1;
    const int64_t n_value = values[0];
    if (n_value < 1 || n_value > MAX_TERMS ||
        length != (size_t)n_value + 1) return -1;
    const size_t n = (size_t)n_value;
    for (size_t index = 0; index < n; ++index)
        if (values[index + 1] < -VALUE_LIMIT || values[index + 1] > VALUE_LIMIT)
            return -1;
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;

    int64_t numerator = 0;
    for (size_t order = 0; order < n; ++order) {
        int64_t difference = 0;
        int64_t coefficient = 1;
        for (size_t index = 0; index <= order; ++index) {
            const int64_t term = values[order - index + 1];
            if (index % 2 == 0) difference += coefficient * term;
            else difference -= coefficient * term;
            if (index < order)
                coefficient = coefficient * (int64_t)(order - index) /
                              (int64_t)(index + 1);
        }
        const int64_t weight = INT64_C(1) << (n - order - 1);
        const int64_t weighted = difference * weight;
        if (order % 2 == 0) numerator += weighted;
        else numerator -= weighted;
    }

    int64_t denominator = INT64_C(1) << n;
    const uint64_t magnitude = numerator < 0
        ? (uint64_t)(-numerator) : (uint64_t)numerator;
    const uint64_t divisor = euler_gcd(magnitude, (uint64_t)denominator);
    numerator /= (int64_t)divisor;
    denominator /= (int64_t)divisor;
    euler_store_i64(output, 0, numerator);
    euler_store_i64(output, 8, denominator);
    return OUTPUT_BYTES;
}
