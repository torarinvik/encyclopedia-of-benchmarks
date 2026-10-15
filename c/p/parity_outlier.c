#include <stddef.h>
#include <stdint.h>

#define MIN_ITEMS 3
#define MAX_ITEMS 65
#define MAX_VALUE INT64_C(2147483647)

int64_t parity_outlier(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1) return -1;
    if (values[0] < MIN_ITEMS || values[0] > MAX_ITEMS || (values[0] & 1) == 0) return -1;
    const size_t count = (size_t)values[0];
    if (length != count + 1) return -1;

    size_t evens = 0, odds = 0;
    int64_t even_value = 0, odd_value = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = values[i + 1];
        if (value < 0 || value > MAX_VALUE) return -1;
        if ((value & 1) == 0) { ++evens; even_value = value; }
        else { ++odds; odd_value = value; }
    }
    if (evens == 1 && odds >= 2) return even_value;
    if (odds == 1 && evens >= 2) return odd_value;
    return -1;
}
