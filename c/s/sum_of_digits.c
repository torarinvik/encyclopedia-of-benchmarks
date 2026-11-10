/* Add the decimal digits of the absolute value of a signed 32-bit integer. */
#include <stdint.h>

int64_t sum_of_digits(int64_t input)
{
    if (input < INT32_MIN || input > INT32_MAX) return -1;
    const uint32_t magnitude = (uint32_t)(input < 0 ? -input : input);
    uint32_t remaining = magnitude;
    uint32_t total = 0;
    while (remaining >= 10) {
        const uint32_t next_quotient = remaining / 10;
        remaining /= 100;
        total += next_quotient + remaining;
    }
    return magnitude - 9 * total;
}
