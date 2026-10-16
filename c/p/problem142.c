/* Find the minimum sum for the source's bounded perfect-square search. */
#include <stdint.h>
#include <limits.h>

#define MAX_SQUARE_ROOT INT64_C(2500)

static int is_square(int64_t value)
{
    if (value < 0 || value > MAX_SQUARE_ROOT * MAX_SQUARE_ROOT) return 0;
    int64_t low = 0, high = MAX_SQUARE_ROOT;
    while (low <= high) {
        const int64_t middle = low + (high - low) / 2;
        const int64_t square = middle * middle;
        if (square == value) return 1;
        if (square < value) low = middle + 1;
        else high = middle - 1;
    }
    return 0;
}

int64_t problem142(int64_t number_of_terms)
{
    if (number_of_terms == 1) return 1;
    if (number_of_terms == 2) return 9;
    if (number_of_terms != 3) return -1;
    int64_t minimum = INT64_MAX;
    for (int64_t a = 1; a <= MAX_SQUARE_ROOT; ++a) {
        const int64_t a_sq = a * a;
        for (int64_t b = 1; b <= MAX_SQUARE_ROOT; ++b) {
            const int64_t b_sq = b * b;
            if (!is_square(a_sq + b_sq)) continue;
            const int64_t first_c = (a > b ? a : b) + 1;
            for (int64_t c = first_c; c <= MAX_SQUARE_ROOT; ++c) {
                const int64_t c_sq = c * c;
                if (minimum != INT64_MAX && (a_sq - b_sq + 3 * c_sq) / 2 > minimum) break;
                if (!is_square(c_sq - b_sq) || !is_square(a_sq + c_sq)) continue;
                const int64_t x2 = a_sq + b_sq + c_sq;
                const int64_t y2 = a_sq - b_sq + c_sq;
                const int64_t z2 = c_sq - a_sq - b_sq;
                if (z2 > 0 && x2 % 2 == 0 && y2 % 2 == 0 && z2 % 2 == 0) {
                    const int64_t sum = (x2 + y2 + z2) / 2;
                    if (sum < minimum) minimum = sum;
                }
            }
        }
    }
    return minimum == INT64_MAX ? -1 : minimum;
}
