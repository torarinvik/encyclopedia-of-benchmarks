#include <stdint.h>

int64_t kynea_numbers(int64_t index)
{
    if (index < 1 || index > 31) return -1;

    int64_t value = (INT64_C(1) << index) + 1;
    int64_t square = value * value;
    return square - 2;
}
