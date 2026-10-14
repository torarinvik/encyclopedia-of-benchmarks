#include <stdint.h>

int64_t number_of_digits(int64_t value)
{
    uint64_t magnitude = value < 0 ? (uint64_t)(-(value + 1)) + UINT64_C(1) : (uint64_t)value;
    int64_t digits = 1;
    while (magnitude >= UINT64_C(10)) {
        magnitude /= UINT64_C(10);
        ++digits;
    }
    return digits;
}
