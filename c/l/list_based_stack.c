#include <stddef.h>
#include <stdint.h>

#define MAX_INITIAL_ITEMS 32
#define MAX_OPERATIONS 64
#define MAX_INPUT_LENGTH 162
#define MAX_STACK_SIZE (MAX_INITIAL_ITEMS + MAX_OPERATIONS)
#define MAX_OUTPUT_BYTES (16 * MAX_OPERATIONS)

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t list_based_stack(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;

    const int64_t raw_initial_count = input[0];
    if (raw_initial_count < 0 || raw_initial_count > MAX_INITIAL_ITEMS) return -1;
    const size_t initial_count = (size_t)raw_initial_count;
    const size_t operation_count_index = 1 + initial_count;
    if (operation_count_index >= length) return -1;

    int64_t initial_items[MAX_INITIAL_ITEMS] = {0};
    for (size_t index = 0; index < initial_count; ++index) {
        const int64_t value = input[1 + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        initial_items[index] = value;
    }

    const int64_t raw_operation_count = input[operation_count_index];
    if (raw_operation_count < 0 || raw_operation_count > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)raw_operation_count;
    int64_t opcodes[MAX_OPERATIONS] = {0};
    int64_t arguments[MAX_OPERATIONS] = {0};
    size_t cursor = operation_count_index + 1;
    size_t validated_size = initial_count;
    for (size_t index = 0; index < operation_count; ++index) {
        if (cursor >= length) return -1;
        const int64_t opcode = input[cursor++];
        opcodes[index] = opcode;
        if (opcode == 1 || opcode == 5) {
            if (cursor >= length) return -1;
            const int64_t value = input[cursor++];
            if (value < INT32_MIN || value > INT32_MAX) return -1;
            arguments[index] = value;
            if (opcode == 1) ++validated_size;
        } else if (opcode == 2 || opcode == 3) {
            if (validated_size == 0) return -1;
            if (opcode == 2) --validated_size;
        } else if (opcode == 4) {
            /* Count does not change the stack. */
        } else if (opcode == 6) {
            validated_size = 0;
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    int64_t stack[MAX_STACK_SIZE] = {0};
    size_t stack_size = initial_count;
    for (size_t index = 0; index < initial_count; ++index)
        stack[index] = initial_items[index];

    uint8_t buffer[MAX_OUTPUT_BYTES] = {0};
    size_t written = 0;
    for (size_t index = 0; index < operation_count; ++index) {
        const int64_t opcode = opcodes[index];
        int64_t result = 0;
        if (opcode == 1) {
            stack[stack_size++] = arguments[index];
        } else if (opcode == 2) {
            result = stack[--stack_size];
        } else if (opcode == 3) {
            result = stack[stack_size - 1];
        } else if (opcode == 4) {
            result = (int64_t)stack_size;
        } else if (opcode == 5) {
            for (size_t item = 0; item < stack_size; ++item) {
                if (stack[item] == arguments[index]) {
                    result = 1;
                    break;
                }
            }
        } else {
            stack_size = 0;
        }
        put_i64_le(buffer, written, opcode);
        put_i64_le(buffer, written + 8, result);
        written += 16;
    }

    if (output == NULL || capacity < written) return -2;
    for (size_t index = 0; index < written; ++index) output[index] = buffer[index];
    return (int64_t)written;
}
