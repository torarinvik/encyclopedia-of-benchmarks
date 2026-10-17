#include <stddef.h>
#include <stdint.h>

#define MAX_CAPACITY 64
#define MAX_OPS 64
#define MAX_INPUT_LENGTH 130
#define MAX_OUTPUT_WORDS (1 + 2 * MAX_OPS)
#define MAX_OUTPUT_BYTES (4 * MAX_OUTPUT_WORDS)

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t min_priority_queue(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_CAPACITY || input[1] < 0 || input[1] > MAX_OPS) return -1;

    const size_t capacity = (size_t)input[0];
    const size_t operation_count = (size_t)input[1];
    int32_t heap[MAX_CAPACITY] = {0};
    int32_t words[MAX_OUTPUT_WORDS];
    size_t heap_size = 0, word_count = 1, query_count = 0, pos = 2;

    for (size_t op = 0; op < operation_count; ++op) {
        if (pos >= length) return -1;
        const int64_t opcode = input[pos++];
        if (opcode == 0) {
            if (pos >= length) return -1;
            const int64_t raw = input[pos++];
            if (raw < INT32_MIN || raw > INT32_MAX || heap_size >= capacity) return -1;
            size_t index = heap_size;
            heap[index] = (int32_t)raw;
            while (index > 0) {
                const size_t parent = (index - 1) / 2;
                if (heap[parent] <= heap[index]) break;
                const int32_t tmp = heap[parent];
                heap[parent] = heap[index];
                heap[index] = tmp;
                index = parent;
            }
            ++heap_size;
        } else if (opcode == 1 || opcode == 2) {
            if (heap_size == 0) return -1;
            const int32_t value = heap[0];
            if (opcode == 2) {
                --heap_size;
                if (heap_size > 0) {
                    heap[0] = heap[heap_size];
                    size_t index = 0;
                    for (;;) {
                        const size_t left = 2 * index + 1;
                        if (left >= heap_size) break;
                        const size_t right = left + 1;
                        size_t child = left;
                        if (right < heap_size && heap[right] < heap[left]) child = right;
                        if (heap[index] <= heap[child]) break;
                        const int32_t tmp = heap[index];
                        heap[index] = heap[child];
                        heap[child] = tmp;
                        index = child;
                    }
                }
            }
            words[word_count++] = (opcode == 1) ? 1 : 2;
            words[word_count++] = value;
            ++query_count;
        } else if (opcode == 3 || opcode == 4) {
            words[word_count++] = (opcode == 3) ? 3 : 4;
            words[word_count++] = (opcode == 3) ? (heap_size == 0) : (heap_size == capacity);
            ++query_count;
        } else return -1;
    }

    if (pos != length || word_count > MAX_OUTPUT_WORDS) return -1;
    words[0] = (int32_t)query_count;
    const size_t bytes = word_count * 4;
    if (bytes > MAX_OUTPUT_BYTES || output == NULL || output_capacity < bytes) return -2;
    uint8_t buffer[MAX_OUTPUT_BYTES];
    for (size_t i = 0; i < word_count; ++i) put_i32_le(buffer, i * 4, words[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return (int64_t)bytes;
}
