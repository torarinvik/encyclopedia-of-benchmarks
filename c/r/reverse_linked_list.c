/* Reverse a bounded doubly linked chain represented by local node indices. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 256
#define MAX_INPUT_LENGTH 257

int64_t reverse_linked_list(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    const size_t output_bytes = 8 * n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t nodes[MAX_N];
    int next[MAX_N], previous_link[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        nodes[i] = input[i + 1];
        next[i] = i + 1 < n ? (int)(i + 1) : -1;
        previous_link[i] = i > 0 ? (int)(i - 1) : -1;
    }
    int previous = -1;
    int current = 0;
    while (current >= 0) {
        const int next_node = next[current];
        next[current] = previous;
        previous_link[current] = next_node;
        previous = current;
        current = next_node;
    }
    const int head = previous;
    int node = head;
    int expected_previous = -1;
    int64_t result[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        if (node < 0 || previous_link[node] != expected_previous) return -1;
        result[i] = nodes[node];
        expected_previous = node;
        node = next[node];
    }
    if (node >= 0) return -1;
    for (size_t i = 0; i < n; ++i) {
        uint64_t bits = (uint64_t)result[i];
        for (size_t byte = 0; byte < 8; ++byte) {
            output[i * 8 + byte] = (uint8_t)(bits & 255);
            bits >>= 8;
        }
    }
    return (int64_t)output_bytes;
}
