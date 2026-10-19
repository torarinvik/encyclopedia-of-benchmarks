#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define SIDE 40
#define MAX_PASSES 40
#define MAX_OUTPUT_BYTES (14 * MAX_PASSES)

static float rounded_add(float left, float right)
{
    volatile float result = left + right;
    return result;
}

static float rounded_mul(float left, float right)
{
    volatile float result = left * right;
    return result;
}

static float rounded_div(float left, float right)
{
    volatile float result = left / right;
    return result;
}

static uint32_t next_random(uint32_t *seed)
{
    *seed = (*seed * 1309u + 13849u) & 65535u;
    return *seed;
}

static float compute_diagonal_cell(size_t selected)
{
    float left[SIDE][SIDE];
    float right[SIDE][SIDE];
    float result[SIDE][SIDE];
    uint32_t seed = 74755u;

    for (size_t row = 0; row < SIDE; ++row) {
        for (size_t column = 0; column < SIDE; ++column) {
            const uint32_t temp = next_random(&seed);
            const int32_t remainder = (int32_t)(temp - (temp / 120u) * 120u);
            left[row][column] = rounded_div((float)(remainder - 60), 3.0f);
        }
    }
    for (size_t row = 0; row < SIDE; ++row) {
        for (size_t column = 0; column < SIDE; ++column) {
            const uint32_t temp = next_random(&seed);
            const int32_t remainder = (int32_t)(temp - (temp / 120u) * 120u);
            right[row][column] = rounded_div((float)(remainder - 60), 3.0f);
        }
    }

    for (size_t row = 0; row < SIDE; ++row) {
        for (size_t column = 0; column < SIDE; ++column) {
            float total = 0.0f;
            for (size_t inner = 0; inner < SIDE; ++inner) {
                const float product = rounded_mul(left[row][inner], right[inner][column]);
                total = rounded_add(total, product);
            }
            result[row][column] = total;
        }
    }
    return result[selected][selected];
}

static size_t write_unsigned(uint64_t value, uint8_t *output)
{
    uint8_t reversed[24];
    size_t count = 0;
    do {
        reversed[count++] = (uint8_t)('0' + value % 10u);
        value /= 10u;
    } while (value != 0);
    for (size_t index = 0; index < count; ++index)
        output[index] = reversed[count - index - 1];
    return count;
}

static size_t write_fixed_six(float value, uint8_t *output)
{
    uint32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    const uint32_t exponent_bits = (bits >> 23) & 255u;
    const uint32_t fraction_bits = bits & 0x7fffffu;
    const uint64_t significand = exponent_bits == 0
        ? fraction_bits
        : (uint64_t)((1u << 23) | fraction_bits);
    const int32_t shift = exponent_bits == 0
        ? -149
        : (int32_t)exponent_bits - 150;
    const uint64_t numerator = significand * 1000000u;
    uint64_t micros;
    if (shift >= 0) {
        micros = numerator << (uint32_t)shift;
    } else {
        const uint32_t denominator_shift = (uint32_t)(-shift);
        if (denominator_shift >= 64) {
            micros = 0;
        } else {
            micros = numerator >> denominator_shift;
            const uint64_t remainder = numerator & ((1ull << denominator_shift) - 1ull);
            const uint64_t halfway = 1ull << (denominator_shift - 1u);
            if (remainder > halfway || (remainder == halfway && (micros & 1u) != 0))
                ++micros;
        }
    }

    size_t position = 0;
    if ((bits >> 31) != 0) output[position++] = (uint8_t)'-';
    position += write_unsigned(micros / 1000000u, output + position);
    output[position++] = (uint8_t)'.';
    const uint32_t fractional = (uint32_t)(micros % 1000000u);
    uint32_t place = 100000u;
    while (place > 0) {
        output[position++] = (uint8_t)('0' + (fractional / place) % 10u);
        place /= 10u;
    }
    output[position++] = (uint8_t)'\n';
    return position;
}

int64_t floatmm(int64_t passes, uint8_t *output, size_t output_capacity)
{
    if (passes < 0 || passes > MAX_PASSES) return -1;
    if (passes == 0) return 0;
    if (output == NULL) return -2;

    uint8_t formatted[MAX_OUTPUT_BYTES];
    size_t required = 0;
    for (int64_t run = 0; run < passes; ++run) {
        const float diagonal = compute_diagonal_cell((size_t)run);
        required += write_fixed_six(diagonal, formatted + required);
    }
    if (output_capacity < required) return -2;
    memcpy(output, formatted, required);
    return (int64_t)required;
}
