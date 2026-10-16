#include <stdint.h>

static int64_t choose_ten(int64_t n)
{
    int64_t result = 1;
    for (int64_t i = 0; i < 10; ++i) result = result * (n - i) / (i + 1);
    return result;
}

int64_t problem493(int64_t picks)
{
    if (picks < 0 || picks > 70) return -1;
    const int64_t denominator = choose_ten(70);
    const int64_t missing = picks > 60 ? 0 : choose_ten(70 - picks);
    const int64_t numerator = 7 * (denominator - missing);
    int64_t whole = numerator / denominator;
    int64_t remainder = numerator % denominator;
    int64_t fraction = 0;
    for (int i = 0; i < 9; ++i) { remainder *= 10; fraction = fraction * 10 + remainder / denominator; remainder %= denominator; }
    remainder *= 10;
    const int64_t guard = remainder / denominator;
    remainder %= denominator;
    int64_t scaled = whole * INT64_C(1000000000) + fraction;
    if (guard > 5 || (guard == 5 && (remainder > 0 || scaled % 2 != 0))) ++scaled;
    return scaled;
}
