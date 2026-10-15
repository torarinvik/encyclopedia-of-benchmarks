/* Check whether n cubed ends with the decimal digits of n. */
#include <stdint.h>

int64_t trimorphic_number(int64_t number)
{
    if (number < 0 || number > 2000000) return -1;
    int64_t modulus = 10;
    int64_t digits = number;
    while (digits >= 10) {
        digits /= 10;
        modulus *= 10;
    }
    const int64_t cube = number * number * number;
    return cube % modulus == number ? 1 : 0;
}
