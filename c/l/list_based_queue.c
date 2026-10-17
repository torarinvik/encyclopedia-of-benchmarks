#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 32
#define MAX_INPUT_LENGTH 66
#define MAX_OUTPUT_WORDS 64

int64_t list_based_queue(const int64_t *input, size_t length,
                         uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_OPS) return -1;
    const size_t op_count = (size_t)input[0];
    int32_t node_values[MAX_OPS];
    int32_t next_node[MAX_OPS];
    int64_t words[MAX_OUTPUT_WORDS];
    size_t allocated = 0, word_count = 0, pos = 1, size = 0;
    int32_t head = -1, tail = -1;

    for (size_t opi = 0; opi < op_count; ++opi) {
        if (pos >= length) return -1;
        const int64_t opcode = input[pos++];
        if (opcode == 0) {
            if (pos >= length) return -1;
            const int64_t value = input[pos++];
            if (value < INT32_MIN || value > INT32_MAX || allocated >= MAX_OPS) return -1;
            const int32_t node = (int32_t)allocated++;
            node_values[node] = (int32_t)value;
            next_node[node] = -1;
            if (tail < 0) head = node;
            else next_node[tail] = node;
            tail = node;
            ++size;
            words[word_count++] = 0; words[word_count++] = 1;
        } else if (opcode == 1) {
            if (head < 0) return -1;
            const int32_t node = head;
            head = next_node[node];
            if (head < 0) tail = -1;
            --size;
            words[word_count++] = 1; words[word_count++] = node_values[node];
        } else if (opcode == 2) {
            if (head < 0) return -1;
            words[word_count++] = 2; words[word_count++] = node_values[head];
        } else if (opcode == 3) {
            head = tail = -1; size = 0;
            words[word_count++] = 3; words[word_count++] = 1;
        } else if (opcode == 4) {
            words[word_count++] = 4; words[word_count++] = size == 0 ? 1 : 0;
        } else if (opcode == 5) {
            words[word_count++] = 5; words[word_count++] = 0;
        } else return -1;
    }
    if (pos != length || length > 1 + 2 * op_count || word_count > MAX_OUTPUT_WORDS) return -1;
    const size_t bytes = word_count * 8;
    if (output == NULL || output_capacity < bytes) return -2;
    for (size_t i = 0; i < word_count; ++i) {
        const uint64_t bits = (uint64_t)words[i];
        for (size_t b = 0; b < 8; ++b) output[8 * i + b] = (uint8_t)(bits >> (8 * b));
    }
    return (int64_t)bytes;
}
