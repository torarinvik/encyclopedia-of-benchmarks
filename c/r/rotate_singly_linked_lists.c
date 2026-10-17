#include <stddef.h>
#include <stdint.h>
#define MAX_N 64
#define MAX_INPUT_LENGTH 66

int64_t rotate_singly_linked_lists(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_N || input[1] < 0 || input[1] > INT32_MAX) return -1;
    const size_t n = (size_t)input[0];
    const int64_t k = input[1];
    if (length != n + 2) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 2] < INT32_MIN || input[i + 2] > INT32_MAX) return -1;
    const size_t bytes = 8 * (n + 1);
    if (output == NULL || capacity < bytes) return -2;

    int32_t nodes[MAX_N];
    int next[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        nodes[i] = (int32_t)input[i + 2];
        next[i] = i + 1 < n ? (int)(i + 1) : -1;
    }
    int head = n > 0 ? 0 : -1;
    if (n > 1 && k > 0) {
        const int tail = (int)n - 1;
        next[tail] = head;
        const size_t shift = (size_t)(k % (int64_t)n);
        const size_t steps = n - shift;
        int new_tail = tail;
        for (size_t i = 0; i < steps; ++i) new_tail = next[new_tail];
        head = next[new_tail];
        next[new_tail] = -1;
    }
    uint64_t count_bits = (uint64_t)n;
    for (size_t b = 0; b < 8; ++b) { output[b] = (uint8_t)(count_bits & 255); count_bits >>= 8; }
    int node = head;
    for (size_t i = 0; i < n; ++i) {
        uint64_t bits = (uint64_t)(int64_t)nodes[node];
        for (size_t b = 0; b < 8; ++b) { output[8 + i * 8 + b] = (uint8_t)(bits & 255); bits >>= 8; }
        if (i + 1 < n) node = next[node];
    }
    return (int64_t)bytes;
}
