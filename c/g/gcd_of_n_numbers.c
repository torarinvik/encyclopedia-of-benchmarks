/* Fold positive signed 32-bit values with Euclid's GCD algorithm. */
#include <stddef.h>
#include <stdint.h>

static int64_t gcd_pair(int64_t left, int64_t right)
{
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t gcd_of_n_numbers(const int64_t *values, size_t length)
{
    if (length == 0 || length > 64) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 1 || values[index] > INT32_MAX) return -1;
    int64_t result = values[0];
    for (size_t index = 1; index < length && result != 1; ++index)
        result = gcd_pair(result, values[index]);
    return result;
}
