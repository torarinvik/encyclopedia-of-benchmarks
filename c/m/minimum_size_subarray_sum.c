#include <stddef.h>
#include <stdint.h>

int64_t minimum_size_subarray_sum(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2) return -1;
    const int64_t target = packed[0];
    const int64_t count = packed[1];
    if (target < 1 || target > 1000000 || count < 0 || count > 256
        || length != (size_t)count + 2) return -1;
    for (int64_t index = 0; index < count; ++index) {
        if (packed[index + 2] < 1 || packed[index + 2] > 1000000) return -1;
    }
    int64_t left = 0, sum = 0, best = count + 1;
    for (int64_t right = 0; right < count; ++right) {
        sum += packed[right + 2];
        while (sum >= target) {
            const int64_t width = right - left + 1;
            if (width < best) best = width;
            sum -= packed[left + 2];
            ++left;
        }
    }
    return best <= count ? best : 0;
}
