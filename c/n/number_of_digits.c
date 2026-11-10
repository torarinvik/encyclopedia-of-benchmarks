#include <stdint.h>

int64_t number_of_digits(int64_t value)
{
    uint64_t magnitude = value < 0 ? (uint64_t)(-(value + 1)) + UINT64_C(1) : (uint64_t)value;
    if (magnitude < 10) return 1;
    int64_t digits = 1;
    while (magnitude >= UINT64_C(10000)) {
        magnitude /= UINT64_C(10000);
        digits += 4;
    }
    if (magnitude < 10) return digits;
    if (magnitude < 100) return digits + 1;
    return digits + (magnitude < 1000 ? 2 : 3);
}
