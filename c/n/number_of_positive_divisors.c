/* Count positive divisors of the absolute value of one signed integer. */
#include <stddef.h>
#include <stdint.h>

int64_t number_of_positive_divisors(const int64_t *values, size_t length)
{
    if (values == NULL || length != 1 || values[0] < -1000000000 || values[0] > 1000000000)
        return -1;
    int64_t remaining = values[0] < 0 ? -values[0] : values[0];
    int64_t count = 1;
    for (int64_t factor = 2; factor * factor <= remaining; ++factor) {
        int64_t exponent = 0;
        while (remaining % factor == 0) {
            remaining /= factor;
            ++exponent;
        }
        count *= exponent + 1;
    }
    if (remaining > 1) count *= 2;
    return count;
}
