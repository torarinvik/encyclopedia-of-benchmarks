#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_coordinate = 1000;
constexpr std::int64_t max_radius = 1000;

std::int64_t classify(std::int64_t x1, std::int64_t y1, std::int64_t r1,
                      std::int64_t x2, std::int64_t y2, std::int64_t r2) {
    const auto dx = x2 - x1;
    const auto dy = y2 - y1;
    if (dx == 0 && dy == 0) return r1 == r2 ? 3 : 0;
    const auto a = -2 * dx;
    const auto b = -2 * dy;
    const auto c = dx * dx + dy * dy + r1 * r1 - r2 * r2;
    const auto discriminant = r1 * r1 * (a * a + b * b) - c * c;
    if (discriminant < 0) return 0;
    return discriminant == 0 ? 1 : 2;
}

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (!input || length != 6) return -1;
    const auto x1 = input[0], y1 = input[1], r1 = input[2];
    const auto x2 = input[3], y2 = input[4], r2 = input[5];
    if (x1 < -max_coordinate || x1 > max_coordinate ||
        y1 < -max_coordinate || y1 > max_coordinate ||
        x2 < -max_coordinate || x2 > max_coordinate ||
        y2 < -max_coordinate || y2 > max_coordinate ||
        r1 < 1 || r1 > max_radius || r2 < 1 || r2 > max_radius) return -1;
    return classify(x1, y1, r1, x2, y2, r2);
}
}

extern "C" std::int64_t circle_circle_intersection_count(
    const std::int64_t* input, std::size_t length) noexcept {
    return solve(input, length);
}
