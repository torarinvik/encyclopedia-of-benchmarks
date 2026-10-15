#include <stddef.h>
#include <stdint.h>

static int64_t lower_bound_range(const int64_t *values, int64_t target,
                                int64_t left, int64_t right)
{
    if (right <= left) return left;
    const int64_t middle = (left + right) / 2;
    if (target == values[middle]) return middle;
    if (target < values[middle])
        return lower_bound_range(values, target, left, middle);
    return lower_bound_range(values, target, middle + 1, right);
}

int64_t lower_bound(const int64_t *values, size_t length, int64_t target)
{
    if (length > 512 || target < INT32_MIN || target > INT32_MAX ||
        (length != 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -1;
        if (i != 0 && values[i - 1] > values[i]) return -1;
    }
    return lower_bound_range(values, target, 0, (int64_t)length - 1);
}
