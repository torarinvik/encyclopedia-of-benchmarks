#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 64
#define MAX_INPUT_LENGTH 129
#define MAX_OUTPUT_BYTES 1536

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void put_record(uint8_t *output, size_t offset,
                       int64_t opcode, int64_t tag, int64_t value) {
    put_i64_le(output, offset, opcode);
    put_i64_le(output, offset + 8, tag);
    put_i64_le(output, offset + 16, value);
}

int64_t linked_stack(const int64_t *input, size_t length,
                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)raw_count;
    int64_t opcodes[MAX_OPERATIONS] = {0};
    int64_t arguments[MAX_OPERATIONS] = {0};
    size_t cursor = 1;
    for (size_t index = 0; index < operation_count; ++index) {
        if (cursor >= length) return -1;
        const int64_t opcode = input[cursor++];
        opcodes[index] = opcode;
        if (opcode == 1) {
            if (cursor >= length) return -1;
            const int64_t value = input[cursor++];
            if (value < INT32_MIN || value > INT32_MAX) return -1;
            arguments[index] = value;
        } else if (opcode < 2 || opcode > 4) {
            return -1;
        }
    }
    if (cursor != length) return -1;

    int64_t node_values[MAX_OPERATIONS + 1] = {0};
    size_t below[MAX_OPERATIONS + 1] = {0};
    size_t node_count = 0, head = 0, written = 0;
    uint8_t buffer[MAX_OUTPUT_BYTES] = {0};
    for (size_t index = 0; index < operation_count; ++index) {
        const int64_t opcode = opcodes[index];
        int64_t tag = 2, value = 0;
        if (opcode == 1) {
            const size_t node = ++node_count;
            node_values[node] = arguments[index];
            below[node] = head;
            head = node;
        } else if (opcode == 2) {
            if (head != 0) {
                tag = 0;
                value = node_values[head];
            }
        } else if (opcode == 3) {
            if (head != 0) {
                tag = 0;
                value = node_values[head];
                head = below[head];
            }
        } else {
            tag = 1;
            value = head == 0;
        }
        put_record(buffer, written, opcode, tag, value);
        written += 24;
    }

    if (output == NULL || capacity < written) return -2;
    for (size_t index = 0; index < written; ++index) output[index] = buffer[index];
    return (int64_t)written;
}
