#include <stddef.h>
#include <stdint.h>

int64_t shortest_subarray_with_sum_at_least_k(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 259) return -1;
    const int64_t target = packed[0];
    const int64_t count = packed[1];
    if (target < -4096 || target > 4096 || count < 0 || count > 256
        || length != (size_t)count + 2) return -1;

    int64_t prefix[257] = {0};
    for (int64_t index = 0; index < count; ++index) {
        const int64_t value = packed[index + 2];
        if (value < -1000 || value > 1000) return -1;
        prefix[index + 1] = prefix[index] + value;
    }

    int64_t deque[257] = {0};
    size_t head = 0, tail = 0;
    int64_t best = count + 1;
    for (size_t right = 0; right <= (size_t)count; ++right) {
        while (head < tail
            && prefix[right] - prefix[(size_t)deque[head]] >= target) {
            const int64_t width = (int64_t)right - deque[head];
            if (width < best) best = width;
            ++head;
        }
        while (head < tail
            && prefix[right] <= prefix[(size_t)deque[tail - 1]]) {
            --tail;
        }
        deque[tail++] = (int64_t)right;
    }
    return best <= count ? best : 0;
}

