#include <cstdint>

/* Minimum number of perfect squares summing to value, using Lagrange's theorem. */
extern "C" std::int64_t sum_of_squares(std::int64_t value)
{
    if (value < 0 || value > 2147483647) return -1;
    if (value == 0) return 0;

    std::int64_t low = 1;
    std::int64_t high = value;
    while (high - low > 1) {
        const std::int64_t middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    const std::int64_t root = low;
    if (root * root == value) return 1;

    std::int64_t second = root;
    for (std::int64_t first = 1; first <= root; ++first) {
        const std::int64_t remainder = value - first * first;
        while (second * second > remainder) --second;
        if (second * second == remainder) return 2;
    }

    std::int64_t reduced = value;
    while (reduced % 4 == 0) reduced /= 4;
    return reduced % 8 == 7 ? 4 : 3;
}
