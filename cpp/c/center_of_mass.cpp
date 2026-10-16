#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr std::int64_t max_particles = 64;
constexpr std::int64_t max_coordinate_units = 1'000'000;
constexpr std::int64_t max_mass_units = 1'000'000;

// Round the exact binary64 input to cents, matching Python round(value, 2).
double round_two_python(double value) noexcept {
    if (value == 0.0) return value;
    const bool negative = value < 0.0;
    double normalized = negative ? -value : value;
    int exponent = 0;
    while (normalized >= 1.0) { normalized *= 0.5; ++exponent; }
    while (normalized < 0.5) { normalized *= 2.0; --exponent; }
    const auto significand = static_cast<std::uint64_t>(normalized * 9007199254740992.0);
    const std::uint64_t numerator = significand * 100;
    const int shift = 53 - exponent;
    std::uint64_t cents = 0;
    if (shift < 0) cents = numerator << static_cast<unsigned>(-shift);
    else if (shift == 0) cents = numerator;
    else if (shift < 64) {
        const std::uint64_t denominator = std::uint64_t{1} << static_cast<unsigned>(shift);
        cents = numerator >> static_cast<unsigned>(shift);
        const std::uint64_t remainder = numerator & (denominator - 1);
        const std::uint64_t half = denominator >> 1;
        if (remainder > half || (remainder == half && (cents & 1) != 0)) ++cents;
    }
    const double rounded = static_cast<double>(cents) / 100.0;
    return negative ? -rounded : rounded;
}
}

extern "C" double center_of_mass(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 2 + 4 * max_particles) return invalid_result;
    const auto selector = values[0];
    const auto count_value = values[1];
    if (selector < 0 || selector > 2 || count_value < 1 || count_value > max_particles ||
        length != 2 + 4 * static_cast<std::size_t>(count_value)) return invalid_result;
    const auto count = static_cast<std::size_t>(count_value);
    for (std::size_t index = 0; index < count; ++index) {
        const auto offset = 2 + 4 * index;
        for (std::size_t coordinate = 0; coordinate < 3; ++coordinate)
            if (values[offset + coordinate] < -max_coordinate_units ||
                values[offset + coordinate] > max_coordinate_units) return invalid_result;
        if (values[offset + 3] < 1 || values[offset + 3] > max_mass_units) return invalid_result;
    }
    double total_mass = 0.0;
    for (std::size_t index = 0; index < count; ++index)
        total_mass += static_cast<double>(values[2 + 4 * index + 3]) / 1000.0;
    double weighted_coordinate = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto offset = 2 + 4 * index;
        const double coordinate = static_cast<double>(values[offset + static_cast<std::size_t>(selector)]) / 1000.0;
        const double mass = static_cast<double>(values[offset + 3]) / 1000.0;
        weighted_coordinate += coordinate * mass;
    }
    return round_two_python(weighted_coordinate / total_mass);
}
