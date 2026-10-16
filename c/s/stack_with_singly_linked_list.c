#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 64
#define MAX_INPUT_LENGTH 129
#define MAX_OUTPUT_BYTES 1536

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void write_record(uint8_t *output, size_t offset, int64_t opcode, int64_t tag, int64_t value) {
    write_i64_le(output, offset, opcode);
    write_i64_le(output, offset + 8, tag);
    write_i64_le(output, offset + 16, value);
}

int64_t stack_with_singly_linked_list(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_OPERATIONS) return -1;
    const size_t count = (size_t)count_value;
    int64_t opcodes[MAX_OPERATIONS] = {0};
    int64_t arguments[MAX_OPERATIONS] = {0};
    size_t cursor = 1;
    for (size_t i = 0; i < count; ++i) {
        if (cursor >= length) return -1;
        const int64_t opcode = input[cursor++];
        opcodes[i] = opcode;
        if (opcode == 1) {
            if (cursor >= length) return -1;
            const int64_t value = input[cursor++];
            if (value < INT32_MIN || value > INT32_MAX) return -1;
            arguments[i] = value;
        } else if (opcode < 2 || opcode > 5) {
            return -1;
        }
    }
    if (cursor != length) return -1;

    int64_t node_values[MAX_OPERATIONS + 1] = {0};
    size_t next_ids[MAX_OPERATIONS + 1] = {0};
    size_t next_node = 0, head = 0, written = 0;
    uint8_t buffer[MAX_OUTPUT_BYTES] = {0};
    for (size_t i = 0; i < count; ++i) {
        const int64_t opcode = opcodes[i];
        int64_t tag = 2, value = 0;
        if (opcode == 1) {
            const size_t node_id = ++next_node;
            node_values[node_id] = arguments[i];
            next_ids[node_id] = head;
            head = node_id;
        } else if (opcode == 2 || opcode == 3) {
            if (head == 0) {
                tag = 4;
                value = 2;
                write_record(buffer, written, opcode, tag, value);
                written += 24;
                break;
            }
            tag = 0;
            value = node_values[head];
            if (opcode == 2) head = next_ids[head];
        } else if (opcode == 4) {
            head = 0;
        } else {
            tag = 0;
            for (size_t node = head; node != 0; node = next_ids[node]) ++value;
        }
        write_record(buffer, written, opcode, tag, value);
        written += 24;
    }
    if (output == NULL || capacity < written) return -2;
    for (size_t i = 0; i < written; ++i) output[i] = buffer[i];
    return (int64_t)written;
}
