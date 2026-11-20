#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_terms = 16;
constexpr std::size_t max_length = 34;
constexpr std::int64_t max_mantissa = INT64_C(16777216);
constexpr double output_scale = 1073741824.0;

void two_sum(double a, double b, double &high, double &low) {
    const double rounded = a + b;
    const double b_virtual = rounded - a;
    const double a_virtual = rounded - b_virtual;
    const double b_roundoff = b - b_virtual;
    const double a_roundoff = a - a_virtual;
    high = rounded;
    low = a_roundoff + b_roundoff;
}

std::size_t grow_expansion(const std::array<double, max_terms + 1> &expansion,
                           std::size_t count, double value,
                           std::array<double, max_terms + 1> &grown) {
    double q = value;
    std::size_t grown_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        double high, low;
        two_sum(q, expansion[i], high, low);
        if (low != 0.0) grown[grown_count++] = low;
        q = high;
    }
    if (q != 0.0 || grown_count == 0) grown[grown_count++] = q;
    return grown_count;
}
}

extern "C" std::int64_t shewchuk_expansion_sum(const std::int64_t *input,
                                                std::size_t length) {
    if (input == nullptr || length < 1 || length > max_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_terms)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;

    std::array<double, max_terms + 1> expansion{};
    std::array<double, max_terms + 1> grown{};
    std::size_t expansion_count = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto mantissa = input[1 + 2 * i];
        const auto exponent = input[2 + 2 * i];
        if (mantissa < -max_mantissa || mantissa > max_mantissa
                || exponent < -30 || exponent > 0) return -1;
        double value = static_cast<double>(mantissa);
        for (std::int64_t shift = 0; shift > exponent; --shift) value *= 0.5;
        if (value == 0.0) continue;
        const auto grown_count = grow_expansion(expansion, expansion_count, value, grown);
        for (std::size_t j = 0; j < grown_count; ++j) expansion[j] = grown[j];
        expansion_count = grown_count;
    }
    std::int64_t result = (INT64_C(1) << 58) + 1;
    for (std::size_t i = 0; i < expansion_count; ++i)
        result += static_cast<std::int64_t>(expansion[i] * output_scale);
    return result;
}
