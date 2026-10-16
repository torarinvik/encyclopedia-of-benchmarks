// Convert the pinned Rust weight units through kilograms, in source order.
#include <cmath>

namespace {
constexpr double weight_factors[23] = {
    1e12, 1e9, 1000.0, 1.0, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15,
    1016.0469088, 907.18474, 50.80234544, 12.70058636,
    6.35029318, 0.45359237, 0.028349523125, 0.0017718451953125, 0.00006479891,
    0.3732417216, 0.0311034768, 0.00155517384, 0.0002, 1.66053906660e-27
};

double to_kilogram_factor(double code) noexcept {
    if (!std::isfinite(code) || code < 0.0 || code > 22.0) return 0.0;
    const int index = static_cast<int>(code);
    if (static_cast<double>(index) != code) return 0.0;
    return weight_factors[index];
}
}

extern "C" double weight(double value, double from_code, double to_code) noexcept {
    if (!std::isfinite(value) || value < -1000000.0 || value > 1000000.0) return -1e300;
    const double from_factor = to_kilogram_factor(from_code);
    const double to_factor = to_kilogram_factor(to_code);
    if (from_factor == 0.0 || to_factor == 0.0) return -1e300;
    const double kilograms = value * from_factor;
    return kilograms / to_factor;
}
