#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double kPi = 3.14159265358979323846264338327950288;
constexpr double kTau = 6.28318530717958647692528676655900576;

double wrap_angle(double angle) noexcept {
    double value = angle - std::floor((angle + kPi) / kTau) * kTau;
    if (value >= kPi) value -= kTau;
    if (value < -kPi) value += kTau;
    return value;
}
}

extern "C" std::int64_t circular_mean_direction(const double* input,
        std::size_t length, double* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 66) return -1;
    const double count_value = input[0];
    if (!std::isfinite(count_value) || std::trunc(count_value) != count_value ||
        count_value < 1.0 || count_value > 64.0) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 1) return -1;

    double sum_cos = 0.0, sum_sin = 0.0;
    double correction_cos = 0.0, correction_sin = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const double raw = input[index + 1];
        if (!std::isfinite(raw) || std::abs(raw) > 8.0 * kPi) return -1;
        const double angle = wrap_angle(raw);
        const double adjusted_cos = std::cos(angle) - correction_cos;
        const double next_cos = sum_cos + adjusted_cos;
        correction_cos = (next_cos - sum_cos) - adjusted_cos;
        sum_cos = next_cos;
        const double adjusted_sin = std::sin(angle) - correction_sin;
        const double next_sin = sum_sin + adjusted_sin;
        correction_sin = (next_sin - sum_sin) - adjusted_sin;
        sum_sin = next_sin;
    }
    const double resultant = std::hypot(sum_cos, sum_sin);
    if (!std::isfinite(resultant) || resultant <= static_cast<double>(count) * 0x1p-28) return -1;
    if (output == nullptr || capacity < 1) return -2;
    output[0] = wrap_angle(std::atan2(sum_sin, sum_cos));
    return 1;
}
