/* A neon number equals the sum of the digits of its square. */
#include <stdint.h>

int64_t neon_number(int64_t number)
{
    if (number < 0) return 0;
    if (number > 3000000000LL) return -1;
    int64_t square = number * number;
    int64_t digit_sum = 0;
    while (square > 0) {
        digit_sum += square % 10;
        square /= 10;
    }
    return digit_sum == number ? 1 : 0;
}
