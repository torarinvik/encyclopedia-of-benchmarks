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

// Reciprocal of the pinned Go binary32 fast-inverse-square-root result.
extern "C" double go_sqrt_f32(double value) noexcept {
    if (!std::isfinite(value) || value < min_value || value > max_value) return -1.0;
    const float number = static_cast<float>(value);
    const float x2 = number * 0.5f;
    std::uint32_t bits;
    std::memcpy(&bits, &number, sizeof(bits));
    bits = UINT32_C(0x5f3759df) - (bits >> 1);
    float inverse_root;
    std::memcpy(&inverse_root, &bits, sizeof(inverse_root));
    inverse_root = newton_step(x2, inverse_root);
    inverse_root = newton_step(x2, inverse_root);
    const float root = 1.0f / inverse_root;
    return static_cast<double>(root);
}
