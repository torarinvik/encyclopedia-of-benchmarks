/* Preserve the Python source's factor-of-two reduction for Proth membership. */
#include <stdint.h>

int64_t is_proth_number(int64_t input)
{
    if (input <= 0) return -1;
    if (input == 1) return 0;

    int64_t remainder = input - 1;
    unsigned exponent = 0;
    while (remainder % 2 == 0) {
        ++exponent;
        remainder /= 2;
    }
    return remainder < (INT64_C(1) << exponent) ? 1 : 0;
}
