#include <stdint.h>

static int64_t gcd(int64_t left, int64_t right)
{
    while (right != 0) {
        int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t problem5(int64_t limit)
{
    if (limit < 1 || limit > 20) return -1;
    int64_t result = 1;
    for (int64_t value = 2; value <= limit; ++value)
        result = (result / gcd(result, value)) * value;
    return result;
}
