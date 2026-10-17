#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH 65

static int reverse_links(int *next, int previous, int current) {
    if (next[current] >= 0) {
        const int head = reverse_links(next, current, next[current]);
        next[current] = previous;
        next[previous] = -1;
        return head;
    }
    next[current] = previous;
    next[previous] = -1;
    return current;
}

int64_t reverse_a_linked_list_using_recusion(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
    const size_t bytes = 4 * n;
    if (output == NULL || capacity < bytes) return -2;

    int32_t nodes[MAX_N];
    int next[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        nodes[i] = (int32_t)input[i + 1];
        next[i] = i + 1 < n ? (int)(i + 1) : -1;
    }
    const int head = reverse_links(next, 0, next[0]);
    int node = head;
    for (size_t i = 0; i < n; ++i) {
        uint32_t bits = (uint32_t)nodes[node];
        for (size_t byte = 0; byte < 4; ++byte) {
            output[i * 4 + byte] = (uint8_t)(bits & 255);
            bits >>= 8;
        }
        if (i + 1 < n) node = next[node];
    }
    return (int64_t)bytes;
}
