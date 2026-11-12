#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxPairs = 64;
constexpr double kDrawScale = 4294967296.0;
constexpr double kTau = 6.283185307179586476925286766559;

bool is_bounded_integer(double value, double minimum, double maximum) noexcept {
    return std::isfinite(value) && std::trunc(value) == value &&
           value >= minimum && value <= maximum;
}
}

extern "C" std::int64_t box_muller_cartesian_normal(
    const double* input, std::size_t length, double* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 1 + 2 * kMaxPairs) return -1;
    if (!is_bounded_integer(input[0], 1.0, static_cast<double>(kMaxPairs))) return -1;
    const auto pair_count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * pair_count) return -1;
    for (std::size_t index = 0; index < 2 * pair_count; ++index)
        if (!is_bounded_integer(input[1 + index], 0.0, 4'294'967'295.0)) return -1;

    const auto result_count = 2 * pair_count;
    if (output == nullptr || capacity < result_count) return -2;
    for (std::size_t pair = 0; pair < pair_count; ++pair) {
        const double radial = (input[1 + 2 * pair] + 1.0) / kDrawScale;
        const double angular = input[2 + 2 * pair] / kDrawScale;
        const double radius = std::sqrt(-2.0 * std::log(radial));
        const double angle = kTau * angular;
        output[2 * pair] = radius * std::cos(angle);
        output[2 * pair + 1] = radius * std::sin(angle);
    }
    return static_cast<std::int64_t>(result_count);
}
