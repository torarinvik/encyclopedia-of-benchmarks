#include <stdint.h>
#include <stddef.h>

int64_t lucas_carmichael_number_predicate(const int64_t *input, size_t length)
{
    if (input == 0 || length != 1) return -1;
    const int64_t value = input[0];
    if (value < 1 || value > 1000000) return -1;

    int64_t remaining = value;
    int64_t divisor = 2;
    int found_factor = 0;
    while (divisor <= remaining / divisor) {
        if (remaining % divisor == 0) {
            found_factor = 1;
            int exponent = 0;
            do {
                remaining /= divisor;
                ++exponent;
            } while (remaining % divisor == 0);
            if (exponent != 1 || (value + 1) % (divisor + 1) != 0) return 0;
        }
        ++divisor;
    }
    if (remaining > 1) {
        if (!found_factor) return 0;
        if ((value + 1) % (remaining + 1) != 0) return 0;
    }
    return found_factor ? 1 : 0;
}
