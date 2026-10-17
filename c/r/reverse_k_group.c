/* Reverse complete k-node groups by relinking a bounded index-based list. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 256
#define MAX_INPUT_LENGTH 258

int64_t reverse_k_group(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_N) return -1;
    const size_t n = (size_t)input[0], k = (size_t)input[1];
    if (length != n + 2) return -1;

    const size_t output_bytes = 8 * n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t nodes[MAX_N];
    int next[MAX_N + 1];
    int head = -1;
    for (size_t i = 0; i < n; ++i) {
        nodes[i] = input[i + 2];
        next[i] = -1;
        if (head < 0) head = (int)i;
        else {
            int tail = head;
            while (next[tail] >= 0) tail = next[tail];
            next[tail] = (int)i;
        }
    }

    size_t remaining = 0;
    for (int node = head; node >= 0; node = next[node]) ++remaining;
    const int dummy = MAX_N;
    next[dummy] = head;
    int previous = dummy;
    while (remaining >= k) {
        const int current = next[previous];
        int moved = next[current];
        for (size_t step = 1; step < k; ++step) {
            next[current] = next[moved];
            next[moved] = next[previous];
            next[previous] = moved;
            moved = next[current];
        }
        previous = current;
        remaining -= k;
    }

    int64_t result[MAX_N];
    size_t index = 0;
    for (int node = next[dummy]; node >= 0; node = next[node]) result[index++] = nodes[node];
    for (size_t i = 0; i < n; ++i) {
        uint64_t bits = (uint64_t)result[i];
        for (size_t byte = 0; byte < 8; ++byte) {
            output[i * 8 + byte] = (uint8_t)(bits & 255);
            bits >>= 8;
        }
    }
    return (int64_t)output_bytes;
}
