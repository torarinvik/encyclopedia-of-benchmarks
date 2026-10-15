/* Complement every bit in the fixed-width unsigned 53-bit domain. */
#include <stdint.h>

#define UINT53_MAX INT64_C(9007199254740991)
#define TWO_TO_53 INT64_C(9007199254740992)

int64_t uint53_bitwise_not(int64_t n)
{
    if (n < 0 || n > UINT53_MAX) return -1;

    int64_t result = 0;
    int64_t bit = 1;
    while (n >= 255) {
        int64_t byte = n % 256;
        result += (255 - byte) * bit;
        n = (n - byte) / 256;
        bit *= 256;
    }
    while (n != 0) {
        int64_t n_bit = n % 2;
        result += (1 - n_bit) * bit;
        n = (n - n_bit) / 2;
        bit *= 2;
    }

    return TWO_TO_53 - bit + result;
}
