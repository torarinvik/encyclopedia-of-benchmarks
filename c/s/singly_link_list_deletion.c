#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH 66

int64_t singly_link_list_deletion(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 2 || input[1] < 1 || input[1] > (int64_t)n) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 2] < INT32_MIN || input[i + 2] > INT32_MAX) return -1;
    const size_t bytes = 4 * (n - 1);
    if (output == NULL || capacity < bytes) return -2;

    int32_t nodes[MAX_N];
    int next[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        nodes[i] = (int32_t)input[i + 2];
        next[i] = i + 1 < n ? (int)(i + 1) : -1;
    }
    int head = 0;
    const size_t position = (size_t)input[1];
    if (position == 1) {
        head = next[head];
    } else {
        int previous = head;
        for (size_t i = 2; i < position; ++i) previous = next[previous];
        const int removed = next[previous];
        next[previous] = next[removed];
    }
    int node = head;
    for (size_t i = 0; i < n - 1; ++i) {
        uint32_t bits = (uint32_t)nodes[node];
        for (size_t byte = 0; byte < 4; ++byte) {
            output[i * 4 + byte] = (uint8_t)(bits & 255);
            bits >>= 8;
        }
        if (i + 1 < n - 1) node = next[node];
    }
    return (int64_t)bytes;
}
