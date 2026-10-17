module list_based_stack;

const usz MAX_INITIAL_ITEMS = 32;
const usz MAX_OPERATIONS = 64;
const usz MAX_INPUT_LENGTH = 162;
const usz MAX_STACK_SIZE = 96;
const usz MAX_OUTPUT_BYTES = 1024;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long list_based_stack(long* input, usz length, char* output, usz capacity)
        @export("list_based_stack") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long raw_initial_count = input[0];
    if (raw_initial_count < 0 || raw_initial_count > 32) return -1;
    usz initial_count = (usz)raw_initial_count;
    usz operation_count_index = 1 + initial_count;
    if (operation_count_index >= length) return -1;

    long initial_items[32];
    for (usz index = 0; index < initial_count; index += 1) {
        long value = input[1 + index];
        if (value < -2147483648 || value > 2147483647) return -1;
        initial_items[index] = value;
    }

    long raw_operation_count = input[operation_count_index];
    if (raw_operation_count < 0 || raw_operation_count > 64) return -1;
    usz operation_count = (usz)raw_operation_count;
    long opcodes[64], arguments[64];
    usz cursor = operation_count_index + 1;
    usz validated_size = initial_count;
    for (usz index = 0; index < operation_count; index += 1) {
        if (cursor >= length) return -1;
        long opcode = input[cursor++];
        opcodes[index] = opcode;
        if (opcode == 1 || opcode == 5) {
            if (cursor >= length) return -1;
            long value = input[cursor++];
            if (value < -2147483648 || value > 2147483647) return -1;
            arguments[index] = value;
            if (opcode == 1) validated_size += 1;
        } else if (opcode == 2 || opcode == 3) {
            if (validated_size == 0) return -1;
            if (opcode == 2) validated_size -= 1;
        } else if (opcode == 4) {
            // Count leaves the stack unchanged.
        } else if (opcode == 6) {
            validated_size = 0;
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    long stack[96];
    usz stack_size = initial_count;
    for (usz index = 0; index < initial_count; index += 1)
        stack[index] = initial_items[index];
    char buffer[1024];
    usz written = 0;
    for (usz index = 0; index < operation_count; index += 1) {
        long opcode = opcodes[index];
        long result = 0;
        if (opcode == 1) {
            stack[stack_size] = arguments[index];
            stack_size += 1;
        } else if (opcode == 2) {
            stack_size -= 1;
            result = stack[stack_size];
        } else if (opcode == 3) {
            result = stack[stack_size - 1];
        } else if (opcode == 4) {
            result = (long)stack_size;
        } else if (opcode == 5) {
            for (usz item = 0; item < stack_size; item += 1) {
                if (stack[item] == arguments[index]) { result = 1; break; }
            }
        } else {
            stack_size = 0;
        }
        put_i64_le(&buffer[0], written, opcode);
        put_i64_le(&buffer[0], written + 8, result);
        written += 16;
    }

    if (output == null || capacity < written) return -2;
    for (usz index = 0; index < written; index += 1) output[index] = buffer[index];
    return (long)written;
}
