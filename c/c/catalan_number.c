/* Return the exact zero-based Catalan number through the signed 64-bit range. */
#include <stdint.h>

static int64_t gcd_i64(int64_t left, int64_t right)
{
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t catalan_number(int64_t n)
{
    if (n < 0 || n > 35) return -1;
    int64_t value = 1;
    for (int64_t index = 1; index <= n; ++index) {
        int64_t numerator = 4 * index - 2;
        int64_t denominator = index + 1;
        const int64_t common = gcd_i64(numerator, denominator);
        numerator /= common;
        denominator /= common;
        value = (value / denominator) * numerator;
    }
    return value;
}
