#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_SAMPLE_COUNT 128

static double round_three_decimals(double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    const int negative = (int)(bits >> 63);
    const unsigned exponent = (unsigned)((bits >> 52) & 0x7ffu);
    const uint64_t fraction = bits & ((UINT64_C(1) << 52) - 1);
    const uint64_t significand = exponent == 0 ? fraction : fraction | (UINT64_C(1) << 52);
    const int exponent2 = exponent == 0 ? -1074 : (int)exponent - 1023 - 52;
    const uint64_t scaled = significand * UINT64_C(1000);
    uint64_t rounded = 0;
    if (exponent2 >= 0) {
        rounded = scaled << (unsigned)exponent2;
    } else {
        const unsigned shift = (unsigned)(-exponent2);
        if (shift < 64) {
            rounded = scaled >> shift;
            if (shift != 0) {
                const uint64_t remainder = scaled & ((UINT64_C(1) << shift) - 1);
                const uint64_t half = UINT64_C(1) << (shift - 1);
                if (remainder > half || (remainder == half && (rounded & 1u) != 0)) ++rounded;
            }
        }
    }
    const double result = (double)rounded / 1000.0;
    return negative ? -result : result;
}

static void put_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t data_transformations(const int64_t *values, size_t length,
                             uint8_t *output, size_t capacity) {
    if (values == NULL || length < 4 || length > MAX_SAMPLE_COUNT + 2) return -1;
    const int64_t mode = values[0];
    const int64_t count_arg = values[1];
    if ((mode != 0 && mode != 1) || count_arg < 2 || count_arg > MAX_SAMPLE_COUNT ||
        length != (size_t)count_arg + 2) return -1;
    const size_t count = (size_t)count_arg;
    int64_t minimum = values[2], maximum = values[2], sum = 0, sum_squares = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = values[index + 2];
        if (value < -100000 || value > 100000) return -1;
        if (value < minimum) minimum = value;
        if (value > maximum) maximum = value;
        sum += value;
        sum_squares += value * value;
    }
    if (minimum == maximum) return -1;
    const size_t output_bytes = count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    if (mode == 0) {
        const double span = (double)(maximum - minimum);
        for (size_t index = 0; index < count; ++index) {
            const double normalized = ((double)(values[index + 2] - minimum)) / span;
            put_f64_le(output, index * 8, round_three_decimals(normalized));
        }
    } else {
        const double average = (double)sum / (double)count;
        const int64_t variance_numerator = (int64_t)count * sum_squares - sum * sum;
        const double variance_denominator = (double)(count * (count - 1));
        const double deviation = sqrt((double)variance_numerator / variance_denominator);
        for (size_t index = 0; index < count; ++index) {
            const double standardized = ((double)values[index + 2] - average) / deviation;
            put_f64_le(output, index * 8, round_three_decimals(standardized));
        }
    }
    return (int64_t)output_bytes;
}
