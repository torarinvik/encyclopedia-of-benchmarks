#include <cmath>
#include <cstdint>
#include <cstring>

namespace {
constexpr double min_value = 1e-6;
constexpr double max_value = 1e6;

float newton_step(float x2, float y) noexcept {
    volatile float product1 = x2 * y;
    volatile float product2 = product1 * y;
    volatile float correction = 1.5f - product2;
    return y * correction;
}
}

extern "C" double fast_inverse_sqrt_go(double value) noexcept {
    if (!std::isfinite(value) || value < min_value || value > max_value) return -1.0;
    const float number = static_cast<float>(value);
    const float x2 = number * 0.5f;
    std::uint32_t bits;
    std::memcpy(&bits, &number, sizeof(bits));
    bits = UINT32_C(0x5f3759df) - (bits >> 1);
    float y;
    std::memcpy(&y, &bits, sizeof(y));
    y = newton_step(x2, y);
    y = newton_step(x2, y);
    return static_cast<double>(y);
}
