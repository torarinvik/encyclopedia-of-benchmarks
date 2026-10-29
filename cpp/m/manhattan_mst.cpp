#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_points = 32;
constexpr std::size_t max_input_length = 1 + 2 * max_points;
constexpr std::int64_t coordinate_limit = 1'000'000;
}

extern "C" std::int64_t manhattan_mst(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 1 || length > max_input_length) return -1;
    const auto count_value = values[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_points)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 1 + 2 * count) return -1;

    std::array<std::int64_t, max_points> x{};
    std::array<std::int64_t, max_points> y{};
    for (std::size_t point = 0; point < count; ++point) {
        x[point] = values[1 + 2 * point];
        y[point] = values[2 + 2 * point];
        if (x[point] < -coordinate_limit || x[point] > coordinate_limit ||
            y[point] < -coordinate_limit || y[point] > coordinate_limit) return -1;
    }

    std::array<bool, max_points> in_tree{};
    std::array<bool, max_points> has_best{};
    std::array<std::int64_t, max_points> best{};
    has_best[0] = true;
    std::int64_t total = 0;
    for (std::size_t step = 0; step < count; ++step) {
        std::size_t selected = count;
        for (std::size_t point = 0; point < count; ++point) {
            if (!in_tree[point] && has_best[point] &&
                (selected == count || best[point] < best[selected])) selected = point;
        }
        if (selected == count) return -1;
        in_tree[selected] = true;
        total += best[selected];
        for (std::size_t point = 0; point < count; ++point) {
            if (in_tree[point]) continue;
            const auto dx = x[selected] - x[point];
            const auto dy = y[selected] - y[point];
            const auto distance = (dx < 0 ? -dx : dx) + (dy < 0 ? -dy : dy);
            if (!has_best[point] || distance < best[point]) {
                has_best[point] = true;
                best[point] = distance;
            }
        }
    }
    return total;
}
