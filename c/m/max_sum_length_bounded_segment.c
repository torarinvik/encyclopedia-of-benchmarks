#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_INPUT 35

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t max_sum_length_bounded_segment(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], lower64 = input[1], upper64 = input[2];
    if (n64 < 1 || n64 > MAX_N || lower64 < 1 || upper64 < lower64 || upper64 > n64 ||
        length != (size_t)(3 + n64)) return -1;
    const size_t n = (size_t)n64, lower = (size_t)lower64, upper = (size_t)upper64;
    int64_t prefix[MAX_N + 1] = {0};
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[3 + i];
        if (value < -10000 || value > 10000) return -1;
        prefix[i + 1] = prefix[i] + value;
    }
    if (output == NULL || capacity < 24) return -2;
    size_t deque[MAX_N + 1], head = 0, tail = 0;
    int64_t best_sum = 0;
    size_t best_start = 0, best_end = 0;
    int have_best = 0;
    for (size_t end = lower; end <= n; ++end) {
        const size_t added = end - lower;
        while (tail > head && prefix[deque[tail - 1]] > prefix[added]) --tail;
        deque[tail++] = added;
        const size_t earliest = end > upper ? end - upper : 0;
        while (head < tail && deque[head] < earliest) ++head;
        const size_t start = deque[head];
        const int64_t sum = prefix[end] - prefix[start];
        if (!have_best || sum > best_sum ||
            (sum == best_sum && (start < best_start || (start == best_start && end < best_end)))) {
            best_sum = sum; best_start = start; best_end = end; have_best = 1;
        }
    }
    store_i64_le(output, 0, best_sum);
    store_i64_le(output, 8, (int64_t)best_start);
    store_i64_le(output, 16, (int64_t)best_end);
    return 24;
}
