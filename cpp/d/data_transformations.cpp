#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MAX_SAMPLE_COUNT = 128;

double round_three_decimals(double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    const bool negative = (bits >> 63) != 0;
    const unsigned exponent = static_cast<unsigned>((bits >> 52) & 0x7ffu);
    const std::uint64_t fraction = bits & ((UINT64_C(1) << 52) - 1);
    const std::uint64_t significand = exponent == 0 ? fraction : fraction | (UINT64_C(1) << 52);
    const int exponent2 = exponent == 0 ? -1074 : static_cast<int>(exponent) - 1023 - 52;
    const std::uint64_t scaled = significand * UINT64_C(1000);
    std::uint64_t rounded = 0;
    if (exponent2 >= 0) {
        rounded = scaled << static_cast<unsigned>(exponent2);
    } else {
        const unsigned shift = static_cast<unsigned>(-exponent2);
        if (shift < 64) {
            rounded = scaled >> shift;
            if (shift != 0) {
                const std::uint64_t remainder = scaled & ((UINT64_C(1) << shift) - 1);
                const std::uint64_t half = UINT64_C(1) << (shift - 1);
                if (remainder > half || (remainder == half && (rounded & 1u) != 0)) ++rounded;
            }
        }
    }
    const double result = static_cast<double>(rounded) / 1000.0;
    return negative ? -result : result;
}

void put_f64_le(std::uint8_t *output, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t data_transformations(const std::int64_t *values, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 4 || length > MAX_SAMPLE_COUNT + 2) return -1;
    const std::int64_t mode = values[0], count_arg = values[1];
    if ((mode != 0 && mode != 1) || count_arg < 2 || count_arg > MAX_SAMPLE_COUNT ||
        length != static_cast<std::size_t>(count_arg) + 2) return -1;
    const std::size_t count = static_cast<std::size_t>(count_arg);
    std::int64_t minimum = values[2], maximum = values[2], sum = 0, sum_squares = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = values[index + 2];
        if (value < -100000 || value > 100000) return -1;
        if (value < minimum) minimum = value;
        if (value > maximum) maximum = value;
        sum += value;
        sum_squares += value * value;
    }
    if (minimum == maximum) return -1;
    const std::size_t output_bytes = count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    if (mode == 0) {
        const double span = static_cast<double>(maximum - minimum);
        for (std::size_t index = 0; index < count; ++index) {
            const double normalized = static_cast<double>(values[index + 2] - minimum) / span;
            put_f64_le(output, index * 8, round_three_decimals(normalized));
        }
    } else {
        const double average = static_cast<double>(sum) / static_cast<double>(count);
        const std::int64_t variance_numerator = static_cast<std::int64_t>(count) * sum_squares - sum * sum;
        const double variance_denominator = static_cast<double>(count * (count - 1));
        const double deviation = std::sqrt(static_cast<double>(variance_numerator) / variance_denominator);
        for (std::size_t index = 0; index < count; ++index) {
            const double standardized = (static_cast<double>(values[index + 2]) - average) / deviation;
            put_f64_le(output, index * 8, round_three_decimals(standardized));
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
