/* Match n against the signed sum of the cubes of its decimal digits. */
#include <stdint.h>

int64_t armstrong_digit_cubes(int64_t n)
{
    if (n < INT64_C(-2147483648) || n > INT64_C(2147483647)) return -1;
    const int64_t original = n;
    int64_t magnitude = n < 0 ? -n : n;
    int64_t sum = 0;
    while (magnitude > 0) {
        const int64_t digit = magnitude % 10;
        sum += digit * digit * digit;
        magnitude /= 10;
    }
    if (original < 0) sum = -sum;
    return sum == original ? 1 : 0;
}
