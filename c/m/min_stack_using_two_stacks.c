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

int64_t min_stack_using_two_stacks(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_OPERATIONS) return -1;
    const size_t count = (size_t)count_value;

    int64_t opcodes[MAX_OPERATIONS], operands[MAX_OPERATIONS];
    size_t position = 1, event_count = 0;
    for (size_t index = 0; index < count; ++index) {
        if (position >= length) return -1;
        const int64_t opcode = input[position++];
        int64_t operand = 0;
        if (opcode == 0) {
            if (position >= length) return -1;
            operand = input[position++];
            if (operand < INT32_MIN || operand > INT32_MAX) return -1;
        } else if (opcode == 1 || opcode == 2 || opcode == 3) {
            ++event_count;
        } else {
            return -1;
        }
        opcodes[index] = opcode;
        operands[index] = operand;
    }
    if (position != length) return -1;

    const size_t needed = (1 + 3 * event_count) * 8;
    if (output == NULL || capacity < needed) return -2;

    uint8_t buffer[MAX_OUTPUT_BYTES] = {0};
    write_i64_le(buffer, 0, (int64_t)event_count);
    int64_t stack[MAX_OPERATIONS], minima[MAX_OPERATIONS];
    size_t depth = 0, minimum_depth = 0, record = 1;
    for (size_t index = 0; index < count; ++index) {
        const int64_t opcode = opcodes[index];
        if (opcode == 0) {
            const int64_t value = operands[index];
            stack[depth++] = value;
            if (minimum_depth == 0 || value <= minima[minimum_depth - 1])
                minima[minimum_depth++] = value;
        } else if (opcode == 1) {
            int64_t exception_flag = 0;
            if (depth == 0) {
                exception_flag = 1;
            } else {
                const int64_t value = stack[--depth];
                if (value == minima[minimum_depth - 1]) --minimum_depth;
            }
            write_i64_le(buffer, record * 8, 1);
            write_i64_le(buffer, (record + 1) * 8, exception_flag);
            write_i64_le(buffer, (record + 2) * 8, 0);
            record += 3;
        } else {
            int64_t exception_flag = 0, value = 0;
            if (depth == 0) {
                exception_flag = 1;
            } else if (opcode == 2) {
                value = stack[depth - 1];
            } else {
                value = minima[minimum_depth - 1];
            }
            write_i64_le(buffer, record * 8, opcode);
            write_i64_le(buffer, (record + 1) * 8, exception_flag);
            write_i64_le(buffer, (record + 2) * 8, value);
            record += 3;
        }
    }
    for (size_t index = 0; index < needed; ++index) output[index] = buffer[index];
    return (int64_t)needed;
}
