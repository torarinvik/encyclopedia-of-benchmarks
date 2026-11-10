/* Return the exact zero-based Catalan number through the signed 64-bit range. */
#include <stdint.h>

int64_t catalan_number(int64_t n)
{
    if (n < 0 || n > 35) return -1;
    int64_t value = 1;
    for (int64_t index = 1; index <= n; ++index) {
        int64_t numerator = 4 * index - 2;
        int64_t denominator = index + 1;
        const int64_t common = (denominator % 3 == 0 ? 3 : 1) * (denominator % 2 == 0 ? 2 : 1);
        numerator /= common;
        denominator /= common;
        value = (value / denominator) * numerator;
    }
    return value;
}
