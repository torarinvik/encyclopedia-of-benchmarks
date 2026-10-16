#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
double round_five_even(double value) noexcept {
    const double scaled = value * 100000.0;
    const double fraction = scaled - std::floor(scaled);
    if (std::abs(fraction - 0.5) <= 1.0e-7) return invalid_result;
    if (value == 0.0) return value;
    const bool negative = value < 0.0;
    double normalized = std::abs(value);
    int exponent = 0;
    while (normalized < 1.0) { normalized *= 2.0; --exponent; }
    while (normalized >= 2.0) { normalized *= 0.5; ++exponent; }
    const std::uint64_t mantissa = static_cast<std::uint64_t>(normalized * 4503599627370496.0);
    const int shift = 52 - exponent;
    if (shift > 70) return negative ? -0.0 : 0.0;
    const std::uint64_t low_product = (mantissa & UINT64_C(0xffffffff)) * UINT64_C(100000);
    const std::uint64_t high_product = (mantissa >> 32) * UINT64_C(100000);
    const std::uint64_t shifted_high = high_product << 32;
    const std::uint64_t low = low_product + shifted_high;
    const std::uint64_t high = (high_product >> 32) + (low < low_product);
    const std::uint64_t quotient = shift < 64 ? (low >> shift) | (high << (64 - shift)) : high >> (shift - 64);
    const int half_bit = shift - 1 < 64 ? static_cast<int>((low >> (shift - 1)) & 1) : static_cast<int>((high >> (shift - 65)) & 1);
    const bool lower_bits = shift - 1 < 64
        ? (low & ((UINT64_C(1) << (shift - 1)) - 1)) != 0
        : low != 0 || (high & ((UINT64_C(1) << (shift - 65)) - 1)) != 0;
    const std::uint64_t rounded = quotient + (half_bit && (lower_bits || (quotient & 1)));
    const double result = static_cast<double>(rounded) / 100000.0;
    return negative ? -result : result;
}
}

extern "C" double light_aberration(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return invalid_result;
    const auto theta_code = values[0], beta_code = values[1];
    if (theta_code < -3141592 || theta_code > 3141592 || beta_code < 0 || beta_code > 999999) return invalid_result;
    const double theta = static_cast<double>(theta_code) / 1000000.0;
    const double beta = static_cast<double>(beta_code) / 1000000.0;
    const double factor = std::sqrt((1.0 - beta) / (1.0 + beta));
    const double angle = 2.0 * std::atan(factor * std::tan(theta / 2.0));
    return round_five_even(angle);
}
