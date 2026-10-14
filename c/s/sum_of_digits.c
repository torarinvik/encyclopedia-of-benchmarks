/* Add the decimal digits of the absolute value of a signed 32-bit integer. */
#include <stdint.h>

int64_t sum_of_digits(int64_t input)
{
    if (input < INT32_MIN || input > INT32_MAX) return -1;
    uint64_t remaining = input < 0 ? (uint64_t)(-input) : (uint64_t)input;
    int64_t total = 0;
    while (remaining != 0) {
        total += (int64_t)(remaining % 10);
        remaining /= 10;
    }
    return total;
}
