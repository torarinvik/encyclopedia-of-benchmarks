module min_stack;

const long MAX_OPERATIONS = 256;
const long MAX_INPUT_VALUES = 513;
const long MAX_OUTPUT_BYTES = 6152;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits = bits >> 8;
    }
}

fn long min_stack(long* input, usz length, char* output, usz capacity)
    @export("min_stack") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > MAX_OPERATIONS) return -1;
    usz count = (usz)count_value;

    long opcodes[256] = {0};
    long operands[256] = {0};
    usz position = 1;
    usz query_count = 0;
    for (usz index = 0; index < count; index++) {
        if (position >= length) return -1;
        long opcode = input[position];
        position++;
        long operand = 0;
        if (opcode == 0) {
            if (position >= length) return -1;
            operand = input[position];
            position++;
            if (operand < -2147483648 || operand > 2147483647) return -1;
        } else if (opcode == 2 || opcode == 3) {
            query_count++;
        } else if (opcode != 1) {
            return -1;
        }
        opcodes[index] = opcode;
        operands[index] = operand;
    }
    if (position != length) return -1;

    usz needed = (1 + 3 * query_count) * 8;
    if (output == null || capacity < needed) return -2;

    char buffer[6152] = {0};
    write_i64_le(buffer, 0, (long)query_count);
    long stack_values[256] = {0};
    long stack_minima[256] = {0};
    usz depth = 0;
    usz record = 1;
    for (usz index = 0; index < count; index++) {
        long opcode = opcodes[index];
        if (opcode == 0) {
            long value = operands[index];
            stack_values[depth] = value;
            stack_minima[depth] = depth == 0 || value < stack_minima[depth - 1]
                ? value : stack_minima[depth - 1];
            depth++;
        } else if (opcode == 1) {
            if (depth > 0) depth--;
        } else {
            long exception_flag = 0;
            long value = 0;
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
    for (usz index = 0; index < needed; index++) output[index] = buffer[index];
    return (long)needed;
}
