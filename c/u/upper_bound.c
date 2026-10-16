#include <stddef.h>
#include <stdint.h>

static int64_t upper_bound_range(const int64_t *values, int64_t target,
                                 int64_t left, int64_t right)
{
    if (right <= left) return left;
    const int64_t middle = (left + right) / 2;
    if (target < values[middle + 1])
        return upper_bound_range(values, target, left, middle);
    return upper_bound_range(values, target, middle + 1, right);
}

int64_t upper_bound(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > 513) return -1;
    const int64_t target = values[0];
    if (target < INT32_MIN || target > INT32_MAX) return -1;
    const size_t array_length = length - 1;
    for (size_t i = 0; i < array_length; ++i) {
        const int64_t value = values[i + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (i != 0 && values[i] > value) return -1;
    }
    return upper_bound_range(values, target, 0, (int64_t)array_length - 1);
}
