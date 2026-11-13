#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t min_vertices = 3;
constexpr std::size_t max_vertices = 12;
constexpr std::size_t max_parseable_length = 26;

std::int64_t squared_length(const std::array<std::int64_t, max_vertices>& x,
                            const std::array<std::int64_t, max_vertices>& y,
                            std::size_t left, std::size_t right) noexcept {
    const auto dx = x[left] - x[right];
    const auto dy = y[left] - y[right];
    return dx * dx + dy * dy;
}
}

extern "C" std::int64_t convex_polygon_minimax_length_triangulation(
        const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (input[0] < static_cast<std::int64_t>(min_vertices) ||
        input[0] > static_cast<std::int64_t>(max_vertices)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * count) return -1;

    std::array<std::int64_t, max_vertices> x{};
    std::array<std::int64_t, max_vertices> y{};
    for (std::size_t vertex = 0; vertex < count; ++vertex) {
        x[vertex] = input[1 + 2 * vertex];
        y[vertex] = input[2 + 2 * vertex];
        if (x[vertex] < -1000 || x[vertex] > 1000 || y[vertex] < -1000 || y[vertex] > 1000) return -1;
    }

    std::int64_t area_twice = 0;
    for (std::size_t vertex = 0; vertex < count; ++vertex) {
        const auto next = (vertex + 1) % count;
        area_twice += x[vertex] * y[next] - y[vertex] * x[next];
    }
    if (area_twice == 0) return -1;
    const std::int64_t orientation = area_twice > 0 ? 1 : -1;
    for (std::size_t edge = 0; edge < count; ++edge) {
        const auto next = (edge + 1) % count;
        const auto dx = x[next] - x[edge];
        const auto dy = y[next] - y[edge];
        for (std::size_t vertex = 0; vertex < count; ++vertex) {
            if (vertex == edge || vertex == next) continue;
            const auto cross = dx * (y[vertex] - y[edge]) - dy * (x[vertex] - x[edge]);
            if (orientation * cross <= 0) return -1;
        }
    }

    std::array<std::array<std::int64_t, max_vertices>, max_vertices> best{};
    for (std::size_t left = 0; left + 1 < count; ++left)
        best[left][left + 1] = squared_length(x, y, left, left + 1);
    for (std::size_t span = 2; span < count; ++span) {
        for (std::size_t left = 0; left + span < count; ++left) {
            const auto right = left + span;
            const auto boundary = squared_length(x, y, left, right);
            std::int64_t optimum = 8'000'001;
            for (std::size_t middle = left + 1; middle < right; ++middle) {
                const auto candidate = std::max({best[left][middle], best[middle][right], boundary});
                if (candidate < optimum) optimum = candidate;
            }
            best[left][right] = optimum;
        }
    }
    return best[0][count - 1];
}
