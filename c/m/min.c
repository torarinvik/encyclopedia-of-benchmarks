#include <stddef.h>
#include <stdint.h>

int64_t min_values(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > 257) return INT64_MIN;
    const int64_t count = values[0];
    if (count < 1 || count > 256 || length != (size_t)count + 1) return INT64_MIN;
    int64_t result = values[1];
    if (result < INT32_MIN || result > INT32_MAX) return INT64_MIN;
    for (size_t index = 2; index < length; ++index) {
        const int64_t value = values[index];
        if (value < INT32_MIN || value > INT32_MAX) return INT64_MIN;
        if (value < result) result = value;
    }
    return result;
}
