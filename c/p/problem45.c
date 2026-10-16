/* Find the next hexagonal number that is also pentagonal. */
#include <stdint.h>

static int64_t integer_sqrt(int64_t value)
{
    int64_t low = 0;
    int64_t high = 200000;
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

int64_t problem45(int64_t start)
{
    if (start < 0 || start > 27693) return -1;
    for (int64_t index = start; index <= 27693; ++index) {
        const int64_t value = index * (2 * index - 1);
        if (is_pentagonal(value)) return value;
    }
    return -1;
}
