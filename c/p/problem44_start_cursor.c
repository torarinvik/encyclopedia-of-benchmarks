/* Find the first pentagonal difference from a bounded start cursor. */
#include <stdint.h>

enum { MAX_START = 2166, MAX_HIGH_INDEX = 2167 };

static int64_t pentagonal(int64_t index)
{
    return index * (3 * index - 1) / 2;
}

static int64_t integer_sqrt(int64_t value)
{
    int64_t low = 0;
    int64_t high = 20000;
    while (high - low > 1) {
        const int64_t middle = (low + high) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

static int is_pentagonal(int64_t value)
{
    const int64_t discriminant = 24 * value + 1;
    const int64_t root = integer_sqrt(discriminant);
    return root * root == discriminant && (root + 1) % 6 == 0;
}

int64_t problem44_start_cursor(int64_t start)
{
    if (start < 1 || start > MAX_START) return -1;
    for (int64_t high = start + 1; high <= MAX_HIGH_INDEX; ++high) {
        const int64_t high_value = pentagonal(high);
        for (int64_t low = high - 1; low > 0; --low) {
            const int64_t low_value = pentagonal(low);
            const int64_t difference = high_value - low_value;
            const int64_t sum = high_value + low_value;
            if (is_pentagonal(difference) && is_pentagonal(sum)) return difference;
        }
    }
    return -1;
}
