#include <stdint.h>

int64_t max_69_number(int64_t value)
{
    if (value < 1 || value > INT64_C(999999999999999999)) return -1;
    int64_t place = 1;
    while (place <= value / 10) place *= 10;
    for (; place > 0; place /= 10) {
        const int64_t digit = (value / place) % 10;
        if (digit == 6) return value + 3 * place;
        if (digit != 9) return -1;
    }
    return -1;
}
