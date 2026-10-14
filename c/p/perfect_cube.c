/* Test whether a signed value is an exact integer cube. */
#include <stdint.h>

int64_t perfect_cube(int64_t value)
{
    if (value < -1000000000000LL || value > 1000000000000LL) return -1;
    const int64_t target = value < 0 ? -value : value;
    int64_t low = 0;
    int64_t high = 10000;
    while (low <= high) {
        const int64_t middle = low + (high - low) / 2;
        const int64_t cube = middle * middle * middle;
        if (cube == target) return 1;
        if (cube < target) low = middle + 1;
        else high = middle - 1;
    }
    return 0;
}
