#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 256
#define MAX_INPUT_VALUES (1 + 2 * MAX_OPERATIONS)
#define MAX_OUTPUT_BYTES ((1 + 3 * MAX_OPERATIONS) * 8)

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t min_stack(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_OPERATIONS) return -1;
    const size_t count = (size_t)count_value;

    int64_t opcodes[MAX_OPERATIONS], operands[MAX_OPERATIONS];
    size_t position = 1, query_count = 0;
    for (size_t i = 0; i < count; ++i) {
        if (position >= length) return -1;
        const int64_t opcode = input[position++];
        int64_t operand = 0;
        if (opcode == 0) {
            if (position >= length) return -1;
            operand = input[position++];
            if (operand < INT32_MIN || operand > INT32_MAX) return -1;
        } else if (opcode == 2 || opcode == 3) {
            ++query_count;
        } else if (opcode != 1) {
            return -1;
        }
        opcodes[i] = opcode;
        operands[i] = operand;
    }
    if (position != length) return -1;

    const size_t needed = (1 + 3 * query_count) * 8;
    if (output == NULL || capacity < needed) return -2;

    uint8_t buffer[MAX_OUTPUT_BYTES] = {0};
    write_i64_le(buffer, 0, (int64_t)query_count);
    int64_t stack_values[MAX_OPERATIONS], stack_minima[MAX_OPERATIONS];
    size_t depth = 0, record = 1;
    for (size_t i = 0; i < count; ++i) {
        const int64_t opcode = opcodes[i];
        if (opcode == 0) {
            const int64_t value = operands[i];
            stack_values[depth] = value;
            stack_minima[depth] = depth == 0 || value < stack_minima[depth - 1]
                ? value : stack_minima[depth - 1];
            ++depth;
        } else if (opcode == 1) {
            if (depth > 0) --depth;
        } else {
            int64_t exception_flag = 0, value = 0;
            if (depth == 0) {
                exception_flag = 1;
            } else if (opcode == 2) {
                value = stack_values[depth - 1];
            } else {
                value = stack_minima[depth - 1];
            }
            write_i64_le(buffer, record * 8, opcode);
            write_i64_le(buffer, (record + 1) * 8, exception_flag);
            write_i64_le(buffer, (record + 2) * 8, value);
            record += 3;
        }
    }
    for (size_t i = 0; i < needed; ++i) output[i] = buffer[i];
    return (int64_t)needed;
}
