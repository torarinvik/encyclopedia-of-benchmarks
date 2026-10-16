/* Count odd periods in square-root continued fractions. */
#include <stdint.h>

enum { MAX_LIMIT = 10000 };

static int64_t integer_sqrt(int64_t value)
{
    int64_t low = 0;
    int64_t high = value + 1;
    while (high - low > 1) {
        const int64_t middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    return low;
}

static int64_t period_length(int64_t value, int64_t root)
{
    int64_t numerator = 0;
    int64_t denominator = 1;
    int64_t coefficient = root;
    int64_t period = 0;
    do {
        numerator = denominator * coefficient - numerator;
        denominator = (value - numerator * numerator) / denominator;
        coefficient = (root + numerator) / denominator;
        ++period;
    } while (coefficient != 2 * root);
    return period;
}

int64_t problem64(int64_t inclusive_limit)
{
    if (inclusive_limit < 0 || inclusive_limit > MAX_LIMIT) return -1;
    int64_t count = 0;
    for (int64_t value = 2; value <= inclusive_limit; ++value) {
        const int64_t root = integer_sqrt(value);
        if (root * root == value) continue;
        if (period_length(value, root) % 2 == 1) ++count;
    }
    return count;
}
