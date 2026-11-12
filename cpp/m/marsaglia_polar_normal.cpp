#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxDraws = 128;
constexpr std::size_t kMaxAttempts = 64;
constexpr double kDrawScale = 2147483648.0;

bool is_bounded_integer(double value, double minimum, double maximum) noexcept {
    return std::isfinite(value) && std::trunc(value) == value &&
           value >= minimum && value <= maximum;
}
}

extern "C" std::int64_t marsaglia_polar_normal(const double* input,
    std::size_t length, double* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > 2 + kMaxDraws) return -1;
    if (!is_bounded_integer(input[0], 2.0, static_cast<double>(kMaxDraws)) ||
        !is_bounded_integer(input[1], 1.0, static_cast<double>(kMaxAttempts))) return -1;
    const auto draw_count = static_cast<std::size_t>(input[0]);
    const auto attempt_cap = static_cast<std::size_t>(input[1]);
    if ((draw_count & 1U) != 0 || length != 2 + draw_count ||
        draw_count < 2 * attempt_cap) return -1;
    for (std::size_t index = 0; index < draw_count; ++index)
        if (!is_bounded_integer(input[2 + index], 0.0, 4294967295.0)) return -1;

    double first = 0.0, second = 0.0;
    bool accepted = false;
    for (std::size_t attempt = 0; attempt < attempt_cap; ++attempt) {
        const double u1 = input[2 + 2 * attempt] / kDrawScale - 1.0;
        const double u2 = input[3 + 2 * attempt] / kDrawScale - 1.0;
        const double radius_squared = u1 * u1 + u2 * u2;
        if (radius_squared <= 0.0 || radius_squared >= 1.0) continue;
        const double scale = std::sqrt(-2.0 * std::log(radius_squared) / radius_squared);
        first = u1 * scale;
        second = u2 * scale;
        accepted = true;
        break;
    }
    if (!accepted) return -1;
    if (output == nullptr || capacity < 2) return -2;
    output[0] = first;
    output[1] = second;
    return 2;
}
