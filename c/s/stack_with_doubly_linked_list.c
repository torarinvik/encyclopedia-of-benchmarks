#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 64
#define MAX_INPUT_LENGTH 129
#define MAX_OUTPUT_BYTES 1536

typedef struct {
    int64_t value;
    size_t next;
    size_t previous;
} stack_node;

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

int64_t stack_with_doubly_linked_list(const int64_t *input, size_t length,
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
        } else if (opcode < 2 || opcode > 4) {
            return -1;
        }
    }
    if (cursor != length) return -1;

    stack_node nodes[MAX_OPERATIONS + 1] = {{0, 0, 0}};
    size_t next_node = 0, head = 0, written = 0;
    uint8_t buffer[MAX_OUTPUT_BYTES] = {0};
    for (size_t i = 0; i < count; ++i) {
        const int64_t opcode = opcodes[i];
        int64_t tag = 2, value = 0;
        if (opcode == 1) {
            const size_t node_id = ++next_node;
            nodes[node_id].value = arguments[i];
            nodes[node_id].next = head;
            nodes[node_id].previous = 0;
            if (head != 0) nodes[head].previous = node_id;
            head = node_id;
        } else if (opcode == 2) {
            if (head != 0) {
                tag = 0;
                value = nodes[head].value;
                head = nodes[head].next;
                if (head != 0) nodes[head].previous = 0;
            }
        } else if (opcode == 3) {
            if (head != 0) {
                tag = 0;
                value = nodes[head].value;
            }
        } else {
            tag = 0;
            for (size_t node = head; node != 0; node = nodes[node].next) ++value;
        }
        write_record(buffer, written, opcode, tag, value);
        written += 24;
    }
    if (output == NULL || capacity < written) return -2;
    for (size_t i = 0; i < written; ++i) output[i] = buffer[i];
    return (int64_t)written;
}
