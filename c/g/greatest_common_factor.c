/* Fold nonnegative integers with portable Euclidean GCD. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 256
#define MAX_SAFE_INTEGER INT64_C(9007199254740991)

static int64_t gcd_nonnegative(int64_t left, int64_t right)
{
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t greatest_common_factor(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_ITEMS + 1) return INT64_MIN;
    const int64_t count = values[0];
    if (count < 1 || count > MAX_ITEMS || length != (size_t)count + 1) return INT64_MIN;
    int64_t result = values[1];
    if (result < 0 || result > MAX_SAFE_INTEGER) return INT64_MIN;
    for (size_t index = 2; index < length; ++index) {
        const int64_t value = values[index];
        if (value < 0 || value > MAX_SAFE_INTEGER) return INT64_MIN;
        result = gcd_nonnegative(result, value);
    }
    return result;
}
