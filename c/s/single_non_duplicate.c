/* Binary search the pair alignment around the unique value. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1025
#define INVALID_RESULT (-2147483649LL)

int64_t single_non_duplicate(const int64_t *values, size_t length)
{
    if (length == 0 || length > MAX_VALUES || length % 2 == 0)
        return INVALID_RESULT;
    size_t left = 0;
    size_t right = length / 2;
    while (left < right) {
        size_t middle = left + (right - left) / 2;
        if (values[middle * 2] == values[middle * 2 + 1]) left = middle + 1;
        else right = middle;
    }
    return values[left * 2];
}
