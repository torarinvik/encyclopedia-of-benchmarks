/* Exact perfect-square check using integer binary search and division. */
#include <stdint.h>

int64_t perfect_square(int64_t input)
{
    if (input < 0) return 0;
    if (input < 2) return 1;
    const uint64_t number = (uint64_t)input;
    uint64_t low = 1;
    uint64_t high = number / 2;
    while (low <= high) {
        const uint64_t middle = low + (high - low) / 2;
        const uint64_t quotient = number / middle;
        if (quotient == middle) {
            if (number % middle == 0) return 1;
            low = middle + 1;
        } else if (quotient < middle) {
            high = middle - 1;
        } else {
            low = middle + 1;
        }
    }
    return 0;
}
