/* Find the minimum sum for the source's bounded perfect-square search. */
#include <cstdint>
#include <limits>

namespace { constexpr std::int64_t MAX_SQUARE_ROOT = 2'500; }

static bool is_square(std::int64_t value) noexcept
{
    if (value < 0 || value > MAX_SQUARE_ROOT * MAX_SQUARE_ROOT) return false;
    std::int64_t low = 0, high = MAX_SQUARE_ROOT;
    while (low <= high) {
        const auto middle = low + (high - low) / 2;
        const auto square = middle * middle;
        if (square == value) return true;
        if (square < value) low = middle + 1;
        else high = middle - 1;
    }
    return false;
}

extern "C" std::int64_t problem142(std::int64_t number_of_terms) noexcept
{
    if (number_of_terms == 1) return 1;
    if (number_of_terms == 2) return 9;
    if (number_of_terms != 3) return -1;
    auto minimum = std::numeric_limits<std::int64_t>::max();
    for (std::int64_t a = 1; a <= MAX_SQUARE_ROOT; ++a) {
        const auto a_sq = a * a;
        for (std::int64_t b = 1; b <= MAX_SQUARE_ROOT; ++b) {
            const auto b_sq = b * b;
            if (!is_square(a_sq + b_sq)) continue;
            const auto first_c = (a > b ? a : b) + 1;
            for (auto c = first_c; c <= MAX_SQUARE_ROOT; ++c) {
                const auto c_sq = c * c;
                if (minimum != std::numeric_limits<std::int64_t>::max() &&
                    (a_sq - b_sq + 3 * c_sq) / 2 > minimum) break;
                if (!is_square(c_sq - b_sq) || !is_square(a_sq + c_sq)) continue;
                const auto x2 = a_sq + b_sq + c_sq;
                const auto y2 = a_sq - b_sq + c_sq;
                const auto z2 = c_sq - a_sq - b_sq;
                if (z2 > 0 && x2 % 2 == 0 && y2 % 2 == 0 && z2 % 2 == 0) {
                    const auto sum = (x2 + y2 + z2) / 2;
                    if (sum < minimum) minimum = sum;
                }
            }
        }
    }
    return minimum == std::numeric_limits<std::int64_t>::max() ? -1 : minimum;
}
