/* Two-ended linear search with source-compatible endpoint priority. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS INT64_C(100000)
#define MAX_SAFE_INTEGER INT64_C(9007199254740991)

int64_t double_linear_search(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 100002) return -1;
    const int64_t target = values[0];
    const int64_t count_value = values[1];
    if (target < -MAX_SAFE_INTEGER || target > MAX_SAFE_INTEGER ||
        count_value < 0 || count_value > MAX_ITEMS ||
        length != (size_t)count_value + 2) return -1;

    const size_t count = (size_t)count_value;
    for (size_t index = 0; index < count; ++index) {
        if (values[index + 2] < -MAX_SAFE_INTEGER || values[index + 2] > MAX_SAFE_INTEGER)
            return -1;
    }

    size_t start = 0, right = count;
    while (start < right) {
        if (values[start + 2] == target) return (int64_t)start;
        if (values[right + 1] == target) return (int64_t)(right - 1);
        ++start;
        --right;
    }
    return -1;
}
