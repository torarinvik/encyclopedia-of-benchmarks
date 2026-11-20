#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t minimum_area_rectangle_arbitrary_orientation(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 34) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 4 || n_value > 16) return -1;
    const std::size_t n = static_cast<std::size_t>(n_value);
    if (length != 1 + 2 * n) return -1;

    std::array<std::int64_t, 16> x{}, y{};
    for (std::size_t i = 0; i < n; ++i) {
        x[i] = input[1 + 2 * i];
        y[i] = input[2 + 2 * i];
        if (x[i] < -32 || x[i] > 32 || y[i] < -32 || y[i] > 32) return -1;
        for (std::size_t j = 0; j < i; ++j)
            if (x[i] == x[j] && y[i] == y[j]) return -1;
    }

    std::int64_t best = -1;
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = i + 1; j < n; ++j) {
            const auto dx1 = x[i] - x[j], dy1 = y[i] - y[j];
            const auto midpoint_x = x[i] + x[j], midpoint_y = y[i] + y[j];
            const auto length1 = dx1 * dx1 + dy1 * dy1;
            for (std::size_t k = 0; k < n; ++k) {
                for (std::size_t l = k + 1; l < n; ++l) {
                    if (k < i || (k == i && l <= j)) continue;
                    if (k == i || k == j || l == i || l == j) continue;
                    if (midpoint_x != x[k] + x[l]
                        || midpoint_y != y[k] + y[l]) continue;
                    const auto dx2 = x[k] - x[l], dy2 = y[k] - y[l];
                    if (length1 != dx2 * dx2 + dy2 * dy2) continue;
                    auto area2 = dx1 * dy2 - dy1 * dx2;
                    if (area2 < 0) area2 = -area2;
                    if (best < 0 || area2 < best) best = area2;
                }
            }
        }
    }
    return best < 0 ? 0 : best;
}
