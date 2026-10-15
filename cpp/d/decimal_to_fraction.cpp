#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t INVALID_RESULT = -1;
constexpr std::int64_t INSUFFICIENT_CAPACITY = -2;
constexpr std::int64_t POWERS10[5] = {1, 10, 100, 1000, 10000};
constexpr std::int64_t POWERS5[5] = {1, 5, 25, 125, 625};

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) output[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}

std::int64_t gcd_positive(std::int64_t a, std::int64_t b) {
    while (b != 0) { const auto remainder = a % b; a = b; b = remainder; }
    return a;
}
}

extern "C" std::int64_t decimal_to_fraction(const std::int64_t *values, std::size_t length,
                                                std::uint8_t *output, std::size_t capacity) noexcept {
    if (values == nullptr || length != 2) return INVALID_RESULT;
    const auto mantissa = values[0];
    const auto places = values[1];
    if (places < 0 || places > 4) return INVALID_RESULT;
    const auto scale = POWERS10[places];
    const auto maximum_mantissa = INT64_C(1000000) * scale;
    if (mantissa < -maximum_mantissa || mantissa > maximum_mantissa || mantissa % POWERS5[places] != 0)
        return INVALID_RESULT;
    if (output == nullptr || capacity < 16) return INSUFFICIENT_CAPACITY;

    const double decimal = static_cast<double>(mantissa) / static_cast<double>(scale);
    std::int64_t numerator;
    std::int64_t denominator;
    if (decimal - static_cast<double>(static_cast<std::int64_t>(decimal)) == 0.0) {
        numerator = static_cast<std::int64_t>(decimal);
        denominator = 1;
    } else {
        std::int64_t digits = places;
        auto magnitude = mantissa < 0 ? -mantissa : mantissa;
        while (digits > 0 && magnitude % 10 == 0) { magnitude /= 10; --digits; }
        numerator = static_cast<std::int64_t>(decimal * static_cast<double>(POWERS10[digits]));
        denominator = POWERS10[digits];
        const auto gcd = gcd_positive(numerator < 0 ? -numerator : numerator, denominator);
        numerator /= gcd;
        denominator /= gcd;
    }
    store_i64_le(output, 0, numerator);
    store_i64_le(output, 8, denominator);
    return 16;
}
