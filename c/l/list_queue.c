#include <stddef.h>
#include <stdint.h>

#define MAX_QUEUE_SIZE 10
#define MAX_OPS 64
#define MAX_INPUT_LENGTH 129
#define MAX_OUTPUT_WORDS 130
#define MAX_OUTPUT_BYTES (4 * MAX_OUTPUT_WORDS)

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t list_queue(const int64_t *input, size_t length,
                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_OPS) return -1;
    const size_t op_count = (size_t)input[0];
    int32_t queue[MAX_QUEUE_SIZE] = {0};
    int32_t words[MAX_OUTPUT_WORDS];
    size_t word_count = 1, query_count = 0, pos = 1, queue_size = 0;
    for (size_t op = 0; op < op_count; ++op) {
        if (pos >= length) return -1;
        const int64_t opcode = input[pos++];
        if (opcode == 0) {
            if (pos >= length) return -1;
            const int64_t raw = input[pos++];
            if (raw < INT32_MIN || raw > INT32_MAX || queue_size >= MAX_QUEUE_SIZE) return -1;
            queue[queue_size++] = (int32_t)raw;
        } else if (opcode == 1) {
            if (queue_size == 0) {
                words[word_count++] = 3;
                words[word_count++] = 0;
            } else {
                const int32_t value = queue[0];
                for (size_t i = 0; i + 1 < MAX_QUEUE_SIZE; ++i) queue[i] = queue[i + 1];
                --queue_size;
                words[word_count++] = 1;
                words[word_count++] = value;
            }
            ++query_count;
        } else if (opcode == 2) {
            words[word_count++] = 2;
            words[word_count++] = (int32_t)queue_size;
            ++query_count;
        } else return -1;
    }
    if (pos != length || word_count + 1 + queue_size > MAX_OUTPUT_WORDS) return -1;
    words[0] = (int32_t)query_count;
    words[word_count++] = (int32_t)queue_size;
    for (size_t i = 0; i < queue_size; ++i) words[word_count++] = queue[i];
    const size_t bytes = word_count * 4;
    if (bytes > MAX_OUTPUT_BYTES || output == NULL || capacity < bytes) return -2;
    uint8_t buffer[MAX_OUTPUT_BYTES];
    for (size_t i = 0; i < word_count; ++i) put_i32_le(buffer, i * 4, words[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return (int64_t)bytes;
}
