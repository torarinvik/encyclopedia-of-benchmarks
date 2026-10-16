module stack_with_doubly_linked_list;

const usz MAX_OPERATIONS = 64;
const usz MAX_INPUT_LENGTH = 129;
const usz MAX_OUTPUT_BYTES = 1536;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
    }
}

fn void write_record(char* output, usz offset, long opcode, long tag, long value) {
    write_i64_le(output, offset, opcode);
    write_i64_le(output, offset + 8, tag);
    write_i64_le(output, offset + 16, value);
}

fn long stack_with_doubly_linked_list(long* input, usz length, char* output, usz capacity) @export("stack_with_doubly_linked_list") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > 64) return -1;
    usz count = (usz)count_value;
    long opcodes[64] = {0};
    long arguments[64] = {0};
    usz cursor = 1;
    for (usz i = 0; i < count; i++) {
        if (cursor >= length) return -1;
        long opcode = input[cursor++];
        opcodes[i] = opcode;
        if (opcode == 1) {
            if (cursor >= length) return -1;
            long value = input[cursor++];
            if (value < -2147483648L || value > 2147483647L) return -1;
            arguments[i] = value;
        } else if (opcode < 2 || opcode > 4) {
            return -1;
        }
    }
    if (cursor != length) return -1;

    long node_values[65] = {0};
    usz next_ids[65] = {0};
    usz prev_ids[65] = {0};
    usz node_count = 0, head = 0, written = 0;
    char buffer[1536] = {0};
    for (usz i = 0; i < count; i++) {
        long opcode = opcodes[i];
        long tag = 2, value = 0;
        if (opcode == 1) {
            usz node_id = ++node_count;
            node_values[node_id] = arguments[i];
            next_ids[node_id] = head;
            prev_ids[node_id] = 0;
            if (head != 0) prev_ids[head] = node_id;
            head = node_id;
        } else if (opcode == 2) {
            if (head != 0) {
                tag = 0;
                value = node_values[head];
                head = next_ids[head];
                if (head != 0) prev_ids[head] = 0;
            }
        } else if (opcode == 3) {
            if (head != 0) { tag = 0; value = node_values[head]; }
        } else {
            tag = 0;
            for (usz node = head; node != 0; node = next_ids[node]) value++;
        }
        write_record(buffer, written, opcode, tag, value);
        written += 24;
    }
    if (output == null || capacity < written) return -2;
    for (usz i = 0; i < written; i++) output[i] = buffer[i];
    return (long)written;
}
