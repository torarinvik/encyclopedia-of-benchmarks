#include <stdint.h>

int64_t finding_number_of_digits_in_a_number(int64_t value)
{
    if (value < 0) return -1;
    uint64_t remaining = (uint64_t)value;
    int64_t count = 0;
    while (remaining != 0) {
        remaining /= 10;
        ++count;
    }
    return count;
}
