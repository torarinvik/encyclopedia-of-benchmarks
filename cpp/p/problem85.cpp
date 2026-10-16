/* Search triangular-number products for the rectangle count nearest the target. */
#include <cmath>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_TARGET = 2'000'000'000;

std::int64_t triangle(std::int64_t side) noexcept
{
    return side * (side + 1) / 2;
}

std::int64_t absolute_difference(std::int64_t left, std::int64_t right) noexcept
{
    const auto difference = left - right;
    return difference < 0 ? -difference : difference;
}
}

extern "C" std::int64_t problem85(std::int64_t target) noexcept
{
    if (target < 0 || target > MAX_TARGET) return -1;
    const auto bound = static_cast<std::int64_t>(
        std::ceil(std::sqrt(static_cast<double>(target * 2)) * 1.1));
    std::int64_t best_product = 0;
    std::int64_t area = 0;
    std::int64_t triangle_a = 0;
    for (std::int64_t a = 1; a < bound; ++a) {
        triangle_a += a;
        const auto estimate =
            (-1.0 + std::sqrt(1.0 + 8.0 * static_cast<double>(target) /
                                       static_cast<double>(triangle_a))) / 2.0;
        const auto b_floor = static_cast<std::int64_t>(std::floor(estimate));
        const auto b_ceil = static_cast<std::int64_t>(std::ceil(estimate));
        const auto first_product = triangle_a * triangle(b_floor);
        const auto second_product = triangle_a * triangle(b_ceil);
        if (absolute_difference(target, first_product) < absolute_difference(target, best_product)) {
            best_product = first_product;
            area = a * b_floor;
        }
        if (absolute_difference(target, second_product) < absolute_difference(target, best_product)) {
            best_product = second_product;
            area = a * b_ceil;
        }
    }
    return area;
}
