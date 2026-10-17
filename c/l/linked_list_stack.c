#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 64
#define MAX_INPUT_LENGTH (1 + 2 * MAX_OPERATIONS)
#define MAX_DEPTH 64
#define MAX_OUTPUT_BYTES (4 + 8 * MAX_OPERATIONS)

typedef struct {
    int32_t value;
    int32_t next;
} StackNode;

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t linked_list_stack(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;

    const size_t operation_count = (size_t)input[0];
    StackNode nodes[MAX_DEPTH];
    int32_t records[2 * MAX_OPERATIONS];
    size_t node_count = 0;
    size_t query_count = 0;
    size_t cursor = 1;
    int32_t top = -1;
    int32_t stack_size = 0;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const int64_t opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor >= length) return -1;
            const int64_t value = input[cursor++];
            if (value < INT32_MIN || value > INT32_MAX
                    || stack_size >= MAX_DEPTH || node_count >= MAX_DEPTH) return -1;
            nodes[node_count].value = (int32_t)value;
            nodes[node_count].next = top;
            top = (int32_t)node_count;
            ++node_count;
            ++stack_size;
        } else if (opcode == 1) {
            if (stack_size == 0 || top < 0) return -1;
            records[2 * query_count] = 1;
            records[2 * query_count + 1] = nodes[(size_t)top].value;
            ++query_count;
            top = nodes[(size_t)top].next;
            --stack_size;
        } else if (opcode == 2) {
            records[2 * query_count] = 2;
            records[2 * query_count + 1] = stack_size;
            ++query_count;
        } else if (opcode == 3) {
            records[2 * query_count] = 3;
            records[2 * query_count + 1] = stack_size == 0 ? 1 : 0;
            ++query_count;
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    const size_t output_bytes = 4 + 8 * query_count;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t buffer[MAX_OUTPUT_BYTES];
    put_i32_le(buffer, 0, (int32_t)query_count);
    for (size_t index = 0; index < 2 * query_count; ++index)
        put_i32_le(buffer, 4 + 4 * index, records[index]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = buffer[byte];
    return (int64_t)output_bytes;
}
