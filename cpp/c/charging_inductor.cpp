#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;

double round_three_python(double value) {
    if (value == 0.0) return value;
    const bool negative = value < 0.0;
    double normalized = negative ? -value : value;
    int exponent = 0;
    while (normalized >= 1.0) { normalized *= 0.5; ++exponent; }
    while (normalized < 0.5) { normalized *= 2.0; --exponent; }
    const auto significand = static_cast<std::uint64_t>(normalized * 9007199254740992.0);
    const std::uint64_t numerator = significand * 1000;
    const int shift = 53 - exponent;
    std::uint64_t milliunits = 0;
    if (shift < 0) milliunits = numerator << static_cast<unsigned>(-shift);
    else if (shift == 0) milliunits = numerator;
    else if (shift < 64) {
        const std::uint64_t denominator = std::uint64_t{1} << static_cast<unsigned>(shift);
        milliunits = numerator >> static_cast<unsigned>(shift);
        const std::uint64_t remainder = numerator & (denominator - 1);
        const std::uint64_t half = denominator >> 1;
        if (remainder > half || (remainder == half && (milliunits & 1) != 0)) ++milliunits;
    }
    const double rounded = static_cast<double>(milliunits) / 1000.0;
    return negative ? -rounded : rounded;
}
}

extern "C" double charging_inductor(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length != 4) return invalid_result;
    const auto voltage_micro = values[0];
    const auto resistance_micro = values[1];
    const auto inductance_micro = values[2];
    const auto time_micro = values[3];
    if (voltage_micro < 1 || voltage_micro > 1000000000000LL ||
        resistance_micro < 10000 || resistance_micro > 1000000000000000LL ||
        inductance_micro < 1 || inductance_micro > 1000000000000LL ||
        time_micro < -1000000000000LL || time_micro > 1000000000000LL) return invalid_result;
    const double source_voltage = static_cast<double>(voltage_micro) / 1000000.0;
    const double resistance = static_cast<double>(resistance_micro) / 1000000.0;
    const double inductance = static_cast<double>(inductance_micro) / 1000000.0;
    const double time_sec = static_cast<double>(time_micro) / 1000000.0;
    const double exponent = (-time_sec * resistance) / inductance;
    if (exponent > 10.0) return invalid_result;
    return round_three_python(source_voltage / resistance * (1.0 - std::exp(exponent)));
}
