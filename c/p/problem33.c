/* Bounded port of TheAlgorithms/Python Project Euler 33. */
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

int64_t problem33(int64_t digit_len)
{
    if (digit_len < 0 || digit_len > 5) return -1;
    int64_t upper = 1;
    for (int64_t index = 0; index < digit_len; ++index) upper *= 10;

    double result = 1.0;
    int64_t denominator = 11;
    for (int64_t numerator = 11; numerator < upper; ++numerator) {
        while (denominator <= 99) {
            if (numerator != denominator && numerator % 10 == denominator / 10 &&
                denominator % 10 != 0 &&
                (double)(numerator / 10) / (double)(denominator % 10) ==
                    (double)numerator / (double)denominator) {
                const int64_t divisor = gcd_i64(numerator, denominator);
                result *= (double)(denominator / divisor) / (double)(numerator / divisor);
            }
            ++denominator;
        }
        denominator = 10;
    }
    return (int64_t)result;
}
