#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024
#define INVALID_RESULT INT64_MIN

int64_t calculate_median(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    const size_t middle = length / 2;
    if (length % 2 != 0) return values[middle] * 2;
    return values[middle - 1] + values[middle];
}
