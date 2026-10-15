/* Binary search the pair alignment around the unique value. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1025
#define INVALID_RESULT (-2147483649LL)

int64_t single_non_duplicate(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_VALUES || length % 2 == 0)
        return INVALID_RESULT;
    size_t left = 0;
    size_t right = length - 1;
    while (left < right) {
        size_t middle = left + (right - left) / 2;
        if (middle % 2 == 0) {
            if (values[middle] == values[middle + 1]) left = middle + 2;
            else right = middle;
        } else {
            if (values[middle] == values[middle - 1]) left = middle + 1;
            else right = middle - 1;
        }
    }
    return values[left];
}
