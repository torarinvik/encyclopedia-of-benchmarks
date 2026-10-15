#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 100000

static int compare_i64(const void *left, const void *right)
{
    const int64_t a = *(const int64_t *)left;
    const int64_t b = *(const int64_t *)right;
    return (a > b) - (a < b);
}

int64_t mex(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_VALUES + 1) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_VALUES || length != (size_t)count_value + 1) return -1;
    const size_t count = (size_t)count_value;
    int64_t values[MAX_VALUES];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        values[index] = value;
    }
    qsort(values, count, sizeof(values[0]), compare_i64);
    int64_t candidate = 0;
    for (size_t index = 0; index < count; ++index) {
        if (values[index] == candidate) ++candidate;
    }
    return candidate;
}
