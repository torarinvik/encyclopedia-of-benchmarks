#include <math.h>
#include <stdint.h>

static int is_pentagonal(int64_t value)
{
    if (value < 1) return 0;
    const int64_t discriminant = 24 * value + 1;
    const int64_t root = (int64_t)sqrt((double)discriminant);
    return root * root == discriminant && (root + 1) % 6 == 0;
}

int64_t problem44(int64_t limit)
{
    if (limit < 1 || limit > 5000) return -1;
    for (int64_t i = 1; i < limit; ++i) {
        const int64_t first = i * (3 * i - 1) / 2;
        for (int64_t j = i; j < limit; ++j) {
            const int64_t second = j * (3 * j - 1) / 2;
            const int64_t difference = second - first;
            if (is_pentagonal(first + second) && is_pentagonal(difference)) return difference;
        }
    }
    return -1;
}
