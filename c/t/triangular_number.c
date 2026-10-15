/* Compute T(n) = n(n+1)/2 without an overflowing intermediate product. */
#include <stdint.h>

int64_t triangular_number(int64_t input)
{
    if (input < 0 || input > INT64_C(4294967295)) return -1;
    const int64_t left = (input & 1) == 0 ? input / 2 : input;
    const int64_t right = (input & 1) == 0 ? input + 1 : (input + 1) / 2;
    return left * right;
}
