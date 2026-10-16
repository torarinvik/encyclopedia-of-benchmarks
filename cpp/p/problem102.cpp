/* Count triangles whose strict interior contains the origin. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VALUES = 6'000;
constexpr std::int64_t MIN_COORD = -1'000;
constexpr std::int64_t MAX_COORD = 1'000;

std::int64_t origin_inside(std::int64_t x1, std::int64_t y1, std::int64_t x2, std::int64_t y2,
                           std::int64_t x3, std::int64_t y3) noexcept
{
    const auto abx = x2 - x1, aby = y2 - y1;
    const auto acx = x3 - x1, acy = y3 - y1;
    auto denominator = acx * aby - acy * abx;
    auto numerator_a = -(x1 * aby - y1 * abx);
    auto numerator_b = x1 * acy - y1 * acx;
    if (denominator == 0) return -1;
    if (denominator < 0) {
        denominator = -denominator;
        numerator_a = -numerator_a;
        numerator_b = -numerator_b;
    }
    return numerator_a > 0 && numerator_b > 0 && numerator_a + numerator_b < denominator;
}
}

extern "C" std::int64_t problem102(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 6 || length > MAX_VALUES || length % 6 != 0) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < MIN_COORD || input[index] > MAX_COORD) return -1;
    std::int64_t count = 0;
    for (std::size_t offset = 0; offset < length; offset += 6) {
        const auto inside = origin_inside(input[offset], input[offset + 1], input[offset + 2],
                                          input[offset + 3], input[offset + 4], input[offset + 5]);
        if (inside < 0) return -1;
        count += inside;
    }
    return count;
}
