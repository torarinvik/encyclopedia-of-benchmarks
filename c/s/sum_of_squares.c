#include <stdint.h>

/* Minimum number of perfect squares summing to value, using Lagrange's theorem. */
int64_t sum_of_squares(int64_t value)
{
    if (value < 0 || value > INT32_MAX) return -1;
    if (value == 0) return 0;

    int64_t low = 1;
    int64_t high = value;
    while (high - low > 1) {
        const int64_t middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    const int64_t root = low;
    if (root * root == value) return 1;

    int64_t second = root;
    for (int64_t first = 1; first <= root; ++first) {
        const int64_t remainder = value - first * first;
        while (second * second > remainder) --second;
        if (second * second == remainder) return 2;
    }

    int64_t reduced = value;
    while (reduced % 4 == 0) reduced /= 4;
    return reduced % 8 == 7 ? 4 : 3;
}
