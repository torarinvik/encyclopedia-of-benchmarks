/* Integer binary exponentiation with Java int wraparound semantics. */
#include <stdint.h>

static int64_t mul32(int64_t x, int64_t y)
{
    const int64_t x_low = x % 65536;
    const int64_t x_high = x / 65536;
    const int64_t y_low = y % 65536;
    const int64_t y_high = y / 65536;
    const int64_t cross = (x_low * y_high + x_high * y_low) % 65536;
    return (x_low * y_low + cross * 65536) % 4294967296LL;
}

int64_t binary_pow(int64_t first, int64_t second)
{
    if (first < -2147483648LL || first > 2147483647LL || second < -2147483648LL || second > 2147483647LL) return -2147483649LL;
    if (second <= 0) return 1;
    int64_t base = first < 0 ? first + 4294967296LL : first;
    int64_t exponent = second;
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent % 2 == 1) result = mul32(result, base);
        base = mul32(base, base);
        exponent /= 2;
    }
    return result >= 2147483648LL ? result - 4294967296LL : result;
}
