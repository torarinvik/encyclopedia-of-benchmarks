#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_coordinate = 100000;
constexpr std::int64_t max_radius = 100000;

std::int64_t count_tangents(std::int64_t x1, std::int64_t y1, std::int64_t r1,
                            std::int64_t x2, std::int64_t y2, std::int64_t r2) {
    const auto dx = x2 - x1;
    const auto dy = y2 - y1;
    const auto distance_squared = dx * dx + dy * dy;
    constexpr std::array<std::int64_t, 2> signs{-1, 1};
    std::int64_t candidates = 0;
    for (auto first_sign : signs) {
        for (auto second_sign : signs) {
            const auto difference = second_sign * r2 - first_sign * r1;
            if (distance_squared >= difference * difference) ++candidates;
        }
    }
    if (r1 == 0 && r2 == 0) return 1;
    if (r1 == 0 || r2 == 0) {
        const auto radius = r1 + r2;
        return distance_squared == radius * radius ? 1 : candidates / 2;
    }
    const auto radius_sum = r1 + r2;
    const auto radius_difference = r1 - r2;
    if (distance_squared == radius_sum * radius_sum ||
        distance_squared == radius_difference * radius_difference) --candidates;
    return candidates;
}

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (!input || length != 6) return -1;
    const auto x1 = input[0], y1 = input[1], r1 = input[2];
    const auto x2 = input[3], y2 = input[4], r2 = input[5];
    if (x1 < -max_coordinate || x1 > max_coordinate ||
        y1 < -max_coordinate || y1 > max_coordinate ||
        x2 < -max_coordinate || x2 > max_coordinate ||
        y2 < -max_coordinate || y2 > max_coordinate ||
        r1 < 0 || r1 > max_radius || r2 < 0 || r2 > max_radius ||
        (x1 == x2 && y1 == y2)) return -1;
    return count_tangents(x1, y1, r1, x2, y2, r2);
}
}

extern "C" std::int64_t common_tangents_two_circles(const std::int64_t* input,
        std::size_t length) noexcept {
    return solve(input, length);
}
