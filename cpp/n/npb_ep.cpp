#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxPairs = 4096;
constexpr std::uint64_t kModulusMask = 70'368'744'177'663ULL;
constexpr std::uint64_t kWordMask = 8'388'607ULL;
constexpr std::uint64_t kMultiplier = 1'220'703'125ULL;
constexpr double kModulusScale = 70'368'744'177'664.0;

bool is_bounded_integer(double value, double minimum, double maximum) noexcept {
    return std::isfinite(value) && std::trunc(value) == value &&
           value >= minimum && value <= maximum;
}

std::uint64_t advance_state(std::uint64_t state) noexcept {
    const auto low = state & kWordMask;
    const auto high = state >> 23;
    const auto multiplier_low = kMultiplier & kWordMask;
    const auto multiplier_high = kMultiplier >> 23;
    const auto low_product = low * multiplier_low;
    const auto cross = (low * multiplier_high + high * multiplier_low) & kWordMask;
    return (low_product + (cross << 23)) & kModulusMask;
}
}

extern "C" std::int64_t npb_ep(const double* input, std::size_t length,
                               double* output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 2 ||
        !is_bounded_integer(input[0], 1.0, static_cast<double>(kMaxPairs)) ||
        !is_bounded_integer(input[1], 1.0, 70'368'744'177'663.0)) return -1;
    const auto pair_count = static_cast<std::size_t>(input[0]);
    if (output == nullptr || capacity < 12) return -2;

    auto state = static_cast<std::uint64_t>(input[1]);
    std::uint64_t histogram[10]{};
    double sum_x = 0.0, sum_y = 0.0;
    for (std::size_t pair = 0; pair < pair_count; ++pair) {
        state = advance_state(state);
        const double x = 2.0 * (static_cast<double>(state) / kModulusScale) - 1.0;
        state = advance_state(state);
        const double y = 2.0 * (static_cast<double>(state) / kModulusScale) - 1.0;
        const double radius_squared = x * x + y * y;
        if (radius_squared <= 0.0 || radius_squared > 1.0) continue;
        const double scale = std::sqrt(-2.0 * std::log(radius_squared) / radius_squared);
        const double normal_x = x * scale, normal_y = y * scale;
        const double extent = std::max(std::abs(normal_x), std::abs(normal_y));
        if (extent < 10.0) ++histogram[static_cast<std::size_t>(extent)];
        sum_x += normal_x;
        sum_y += normal_y;
    }
    for (std::size_t bin = 0; bin < 10; ++bin) output[bin] = static_cast<double>(histogram[bin]);
    output[10] = sum_x;
    output[11] = sum_y;
    return 12;
}
