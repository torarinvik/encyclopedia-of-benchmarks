module linked_stack;

const usz MAX_OPERATIONS = 64;
const usz MAX_INPUT_LENGTH = 129;
const usz MAX_OUTPUT_BYTES = 1536;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn void put_record(char* output, usz offset, long opcode, long tag, long value) {
    put_i64_le(output, offset, opcode);
    put_i64_le(output, offset + 8, tag);
    put_i64_le(output, offset + 16, value);
}

long linked_stack(long* input, usz length, char* output, usz capacity)
        @export("linked_stack") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long raw_count = input[0];
    if (raw_count < 0 || raw_count > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)raw_count;
    long opcodes[64], arguments[64];
    usz cursor = 1;
    for (usz index = 0; index < operation_count; index += 1) {
        if (cursor >= length) return -1;
        long opcode = input[cursor++];
        opcodes[index] = opcode;
        if (opcode == 1) {
            if (cursor >= length) return -1;
            long value = input[cursor++];
            if (value < -2147483648 || value > 2147483647) return -1;
            arguments[index] = value;
        } else if (opcode < 2 || opcode > 4) {
            return -1;
        }
    }
    if (cursor != length) return -1;

    long node_values[65];
    usz below[65];
    usz node_count = 0, head = 0, written = 0;
    char buffer[1536];
    for (usz index = 0; index < operation_count; index += 1) {
        long opcode = opcodes[index];
        long tag = 2, value = 0;
        if (opcode == 1) {
            usz node = ++node_count;
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
            value = head == 0 ? 1 : 0;
        }
        put_record(&buffer[0], written, opcode, tag, value);
        written += 24;
    }

    if (output == null || capacity < written) return -2;
    for (usz index = 0; index < written; index += 1) output[index] = buffer[index];
    return (long)written;
}
