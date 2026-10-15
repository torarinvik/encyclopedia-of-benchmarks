#include <stddef.h>
#include <stdint.h>

int64_t set_kth_bit(const int64_t *input, size_t length)
{
    if (input == NULL || length != 2) return -1;
    const int64_t number = input[0];
    const int64_t bit = input[1];
    if (number < 0 || number > 2147483647 || bit < 0 || bit > 30) return -1;
    return number | (INT64_C(1) << bit);
}
