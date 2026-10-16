#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = -1; constexpr std::int64_t max_n = 100, max_component = 1000; }

extern "C" std::int64_t in_static_equilibrium(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 5) return invalid_result;
    const std::int64_t n_value = values[0];
    if (n_value < 1 || n_value > max_n || length != 1 + 4 * static_cast<std::size_t>(n_value)) return invalid_result;
    const std::size_t n = static_cast<std::size_t>(n_value);
    std::int64_t total_moment = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto fx = values[1 + i], fy = values[1 + n + i];
        const auto lx = values[1 + 2 * n + i], ly = values[1 + 3 * n + i];
        if (fx < -max_component || fx > max_component || fy < -max_component || fy > max_component ||
            lx < -max_component || lx > max_component || ly < -max_component || ly > max_component) return invalid_result;
        total_moment += lx * fy - ly * fx;
    }
    return total_moment == 0 ? 1 : 0;
}
