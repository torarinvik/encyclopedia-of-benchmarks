/* Count repeated decimal digit-sum steps until one digit remains. */
#include <stdint.h>

int64_t additive_persistence(int64_t input)
{
    if (input < 0) return -1;
    int64_t steps = 0;
    while (input >= 10) {
        int64_t sum = 0;
        int64_t remaining = input;
        while (remaining > 0) {
            sum += remaining % 10;
            remaining /= 10;
        }
        input = sum;
        ++steps;
    }
    return steps;
}
