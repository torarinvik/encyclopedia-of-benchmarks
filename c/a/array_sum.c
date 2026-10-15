/* Sum a bounded array of nonnegative signed integers. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)
#define MAX_COUNT 1024
#define MAX_VALUE INT64_C(1000000000)

int64_t array_sum(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_COUNT) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (length != count + 1) return INVALID_RESULT;
    int64_t sum = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = values[i + 1];
        if (value < 0 || value > MAX_VALUE) return INVALID_RESULT;
        sum += value;
    }
    return sum;
}
