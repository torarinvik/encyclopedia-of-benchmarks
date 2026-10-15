/* Check whether the sum of the decimal digits' factorials equals the input. */
#include <stdint.h>

int64_t strong_number(int64_t number)
{
    if (number < INT32_MIN || number > INT32_MAX) return -1;
    if (number < 0) return 0;
    int64_t remaining = number;
    int64_t sum = 0;
    if (remaining == 0) sum = 1; /* The decimal representation of zero has one zero digit. */
    while (remaining > 0) {
        const int64_t digit = remaining % 10;
        int64_t factorial = 1;
        for (int64_t factor = 2; factor <= digit; ++factor) factorial *= factor;
        sum += factorial;
        remaining /= 10;
    }
    return sum == number ? 1 : 0;
}
