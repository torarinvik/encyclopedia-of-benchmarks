#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH INT64_C(4096)
#define INT32_MIN_VALUE (-INT64_C(2147483648))
#define INT32_MAX_VALUE INT64_C(2147483647)

static int is_local_maximum(const int64_t *values, int64_t length, int64_t index)
{
    if (index == 0) return values[0] > values[1];
    if (index == length - 1) return values[index] > values[index - 1];
    return values[index] > values[index - 1] && values[index] > values[index + 1];
}

static int64_t count_range(const int64_t *values, int64_t length, int64_t start, int64_t end)
{
    if (start == end) return is_local_maximum(values, length, start) ? 1 : 0;
    const int64_t middle = (start + end) / 2;
    return count_range(values, length, start, middle) +
           count_range(values, length, middle + 1, end);
}

/* Count strict local maxima using the pinned recursive partition. */
int64_t number_of_local_maximum_points(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < INT32_MIN_VALUE || values[i] > INT32_MAX_VALUE) return -1;
    }
    if (length == 1) return 0; /* Source compares the sole element with undefined. */
    return count_range(values, (int64_t)length, 0, (int64_t)length - 1);
}
