// Sherman rainfall intensity curve over bounded integer inputs.
#include <cmath>
#include <cstddef>
#include <cstdint>

constexpr double INVALID_RESULT = -1.0e300;

extern "C" double rainfall_intensity(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 6) return INVALID_RESULT;
    const auto k = values[0], a = values[1], b = values[2], c = values[3], period = values[4], duration = values[5];
    if (k < 1 || k > 1000 || a < 1 || a > 3 || b < 1 || b > 100 || c < 1 || c > 3 ||
        period < 1 || period > 100 || duration < 1 || duration > 1000) return INVALID_RESULT;
    return (static_cast<double>(k) * std::pow(static_cast<double>(period), static_cast<double>(a))) /
        std::pow(static_cast<double>(duration + b), static_cast<double>(c));
}
