/* Return 1 when n is divisible by its base-10 digit sum, else 0. */
#include <stdint.h>

int64_t harshad_number(int64_t n)
{
    if (n <= 0 || n > INT32_MAX) return -1;
    int64_t remaining = n;
    int64_t digit_sum = 0;
    while (remaining > 0) {
        digit_sum += remaining % 10;
        remaining /= 10;
    }
    return n % digit_sum == 0 ? 1 : 0;
}
