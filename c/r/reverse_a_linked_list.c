/* Reverse a bounded singly linked list represented by local node indices. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 128
#define MAX_INPUT_LENGTH 129

int64_t reverse_a_linked_list(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
    const size_t output_bytes = 4 * n;
    if (output == NULL || capacity < output_bytes) return -2;

    int32_t nodes[MAX_N];
    int next[MAX_N];
    int head = -1;
    for (size_t i = 0; i < n; ++i) {
        nodes[i] = (int32_t)input[i + 1];
        next[i] = -1;
        if (head < 0) head = (int)i;
        else {
            int tail = head;
            while (next[tail] >= 0) tail = next[tail];
            next[tail] = (int)i;
        }
    }
    int previous = -1;
    int current = head;
    while (current >= 0) {
        const int next_node = next[current];
        next[current] = previous;
        previous = current;
        current = next_node;
    }
    head = previous;
    for (size_t index = 0; index < n; ++index) {
        int node = head;
        for (size_t step = 0; step < index; ++step) node = next[node];
        uint32_t bits = (uint32_t)nodes[node];
        for (size_t byte = 0; byte < 4; ++byte) {
            output[index * 4 + byte] = (uint8_t)(bits & 255);
            bits >>= 8;
        }
    }
    return (int64_t)output_bytes;
}
