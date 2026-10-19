#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t SIDE = 40;
constexpr std::int64_t MAX_PASSES = 40;
constexpr std::size_t MAX_OUTPUT_BYTES = 14 * SIDE;

float rounded_add(float left, float right)
{
    volatile float result = left + right;
    return result;
}

float rounded_mul(float left, float right)
{
    volatile float result = left * right;
    return result;
}

float rounded_div(float left, float right)
{
    volatile float result = left / right;
    return result;
}

std::uint32_t next_random(std::uint32_t &seed)
{
    seed = (seed * 1309u + 13849u) & 65535u;
    return seed;
}

float compute_diagonal_cell(std::size_t selected)
{
    float left[SIDE][SIDE]{};
    float right[SIDE][SIDE]{};
    float result[SIDE][SIDE]{};
    std::uint32_t seed = 74755u;
    for (std::size_t row = 0; row < SIDE; ++row) {
        for (std::size_t column = 0; column < SIDE; ++column) {
            const std::uint32_t temp = next_random(seed);
            const std::int32_t remainder = static_cast<std::int32_t>(temp - (temp / 120u) * 120u);
            left[row][column] = rounded_div(static_cast<float>(remainder - 60), 3.0f);
        }
    }
    for (std::size_t row = 0; row < SIDE; ++row) {
        for (std::size_t column = 0; column < SIDE; ++column) {
            const std::uint32_t temp = next_random(seed);
            const std::int32_t remainder = static_cast<std::int32_t>(temp - (temp / 120u) * 120u);
            right[row][column] = rounded_div(static_cast<float>(remainder - 60), 3.0f);
        }
    }
    for (std::size_t row = 0; row < SIDE; ++row) {
        for (std::size_t column = 0; column < SIDE; ++column) {
            float total = 0.0f;
            for (std::size_t inner = 0; inner < SIDE; ++inner) {
                const float product = rounded_mul(left[row][inner], right[inner][column]);
                total = rounded_add(total, product);
            }
            result[row][column] = total;
        }
    }
    return result[selected][selected];
}

std::size_t write_unsigned(std::uint64_t value, std::uint8_t *output)
{
    std::uint8_t reversed[24];
    std::size_t count = 0;
    do {
        reversed[count++] = static_cast<std::uint8_t>('0' + value % 10u);
        value /= 10u;
    } while (value != 0);
    for (std::size_t index = 0; index < count; ++index)
        output[index] = reversed[count - index - 1];
    return count;
}

std::size_t write_fixed_six(float value, std::uint8_t *output)
{
    std::uint32_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    const std::uint32_t exponent_bits = (bits >> 23) & 255u;
    const std::uint32_t fraction_bits = bits & 0x7fffffu;
    const std::uint64_t significand = exponent_bits == 0
        ? fraction_bits
        : ((1u << 23) | fraction_bits);
    const std::int32_t shift = exponent_bits == 0
        ? -149
        : static_cast<std::int32_t>(exponent_bits) - 150;
    const std::uint64_t numerator = significand * 1000000u;
    std::uint64_t micros;
    if (shift >= 0) {
        micros = numerator << static_cast<std::uint32_t>(shift);
    } else {
        const std::uint32_t denominator_shift = static_cast<std::uint32_t>(-shift);
        if (denominator_shift >= 64) {
            micros = 0;
        } else {
            micros = numerator >> denominator_shift;
            const std::uint64_t remainder = numerator & ((1ull << denominator_shift) - 1ull);
            const std::uint64_t halfway = 1ull << (denominator_shift - 1u);
            if (remainder > halfway || (remainder == halfway && (micros & 1u) != 0)) ++micros;
        }
    }

    std::size_t position = 0;
    if ((bits >> 31) != 0) output[position++] = static_cast<std::uint8_t>('-');
    position += write_unsigned(micros / 1000000u, output + position);
    output[position++] = static_cast<std::uint8_t>('.');
    const std::uint32_t fractional = static_cast<std::uint32_t>(micros % 1000000u);
    std::uint32_t place = 100000u;
    while (place > 0) {
        output[position++] = static_cast<std::uint8_t>('0' + (fractional / place) % 10u);
        place /= 10u;
    }
    output[position++] = static_cast<std::uint8_t>('\n');
    return position;
}
}

extern "C" std::int64_t floatmm(std::int64_t passes, std::uint8_t *output,
    std::size_t output_capacity) noexcept
{
    if (passes < 0 || passes > MAX_PASSES) return -1;
    if (passes == 0) return 0;
    if (output == nullptr) return -2;

    std::uint8_t formatted[MAX_OUTPUT_BYTES]{};
    std::size_t required = 0;
    for (std::int64_t run = 0; run < passes; ++run) {
        const float diagonal = compute_diagonal_cell(static_cast<std::size_t>(run));
        required += write_fixed_six(diagonal, formatted + required);
    }
    if (output_capacity < required) return -2;
    std::memcpy(output, formatted, required);
    return static_cast<std::int64_t>(required);
}
