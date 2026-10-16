#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr std::int64_t max_flow_count = 8;
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
        const auto remainder = numerator & (denominator - 1);
        const auto half = denominator >> 1;
        if (remainder > half || (remainder == half && (cents & 1) != 0)) ++cents;
    }
    const double rounded = static_cast<double>(cents) / 100.0;
    return negative ? -rounded : rounded;
}
}
extern "C" double present_value(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > 10) return invalid_result;
    const auto count_value = values[0];
    const auto rate_ppm = values[1];
    if (count_value < 1 || count_value > max_flow_count || length != 2 + static_cast<std::size_t>(count_value) ||
        (rate_ppm != 0 && rate_ppm != 1000000)) return invalid_result;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count_value); ++i)
        if (values[i + 2] < -1000000 || values[i + 2] > 1000000 || values[i + 2] % 125 != 0) return invalid_result;
    const double rate = static_cast<double>(rate_ppm) / 1000000.0;
    double total = 0.0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count_value); ++i) {
        const double cash_flow = static_cast<double>(values[i + 2]) / 1000.0;
        total += cash_flow / std::pow(1.0 + rate, static_cast<double>(i));
    }
    return round_two_python(total);
}
