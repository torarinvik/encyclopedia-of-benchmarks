/* Count reduced fractions strictly between 1/3 and 1/2. */
#include <stdint.h>

enum { MAX_DENOMINATOR = 12000 };

static int64_t gcd_i64(int64_t left, int64_t right)
{
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t problem73(int64_t max_denominator)
{
    if (max_denominator < 0 || max_denominator > MAX_DENOMINATOR) return -1;
    int64_t count = 0;
    for (int64_t denominator = 0; denominator <= max_denominator; ++denominator) {
        int64_t numerator_start = denominator / 3 + 1;
        int64_t numerator_step = 1;
        if (denominator % 2 == 0) {
            numerator_start += 1 - numerator_start % 2;
            numerator_step = 2;
        }
        const int64_t numerator_end = (denominator + 1) / 2;
        for (int64_t numerator = numerator_start; numerator < numerator_end;
             numerator += numerator_step) {
            if (gcd_i64(numerator, denominator) == 1) ++count;
        }
    }
    return count;
}
