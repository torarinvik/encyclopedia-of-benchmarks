#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t sliding_window_maximum(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_LENGTH + 2) return -1;
    int64_t n_value = input[0], k_value = input[1];
    if (n_value < 0 || n_value > MAX_LENGTH || k_value < 1 || k_value > MAX_LENGTH) return -1;
    size_t n = (size_t)n_value, k = (size_t)k_value;
    if (length != n + 2) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;
    size_t windows = n >= k ? n - k + 1 : 0;
    if (capacity < windows * 8 || (windows != 0 && output == NULL)) return -2;
    size_t deque[MAX_LENGTH], head = 0, tail = 0, out = 0;
    for (size_t i = 0; i < n; ++i) {
        while (head < tail && deque[head] + k <= i) ++head;
        while (head < tail && input[2 + deque[tail - 1]] < input[2 + i]) --tail;
        deque[tail++] = i;
        if (i + 1 >= k) store_i64_le(output, out++ * 8, input[2 + deque[head]]);
    }
    return (int64_t)windows;
}
