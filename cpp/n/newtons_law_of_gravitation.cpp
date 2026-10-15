// Solve Newton's law of gravitation for one missing parameter.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr double GRAVITATIONAL_CONSTANT = 6.6743e-11;
}

extern "C" double newtons_law_of_gravitation(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return INVALID_RESULT;
    const auto target = values[0], a = values[1], b = values[2], c = values[3];
    if (target < 0 || target > 3 || a < 1 || a > 1000 || b < 1 || b > 1000 || c < 1 || c > 1000) return INVALID_RESULT;
    switch (target) {
        case 0: return GRAVITATIONAL_CONSTANT * (static_cast<double>(a) * static_cast<double>(b)) / (static_cast<double>(c) * static_cast<double>(c));
        case 1: return static_cast<double>(a) * (static_cast<double>(c) * static_cast<double>(c)) / (GRAVITATIONAL_CONSTANT * static_cast<double>(b));
        case 2: return static_cast<double>(a) * (static_cast<double>(c) * static_cast<double>(c)) / (GRAVITATIONAL_CONSTANT * static_cast<double>(b));
        default: return std::sqrt((GRAVITATIONAL_CONSTANT * (static_cast<double>(b) * static_cast<double>(c))) / static_cast<double>(a));
    }
}
