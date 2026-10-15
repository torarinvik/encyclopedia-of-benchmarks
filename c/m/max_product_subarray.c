/* Maximum contiguous product with current maximum/minimum tracking. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN

int64_t max_product_subarray(const int64_t *values, size_t length)
{
    if (length > 9 || (length > 0 && values == NULL)) return INVALID_RESULT;
    if (length == 0) return 0;
    int64_t max_now = values[0], min_now = values[0], max_product = values[0];
    if (values[0] < -10 || values[0] > 10) return INVALID_RESULT;
    for (size_t i = 1; i < length; ++i) {
        int64_t value = values[i];
        if (value < -10 || value > 10) return INVALID_RESULT;
        if (value < 0) { int64_t swap = max_now; max_now = min_now; min_now = swap; }
        int64_t product = max_now * value;
        max_now = value > product ? value : product;
        product = min_now * value;
        min_now = value < product ? value : product;
        if (max_now > max_product) max_product = max_now;
    }
    return max_product;
}
