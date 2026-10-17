module linkedlist_implentation_usingarray;

const usz MAX_INPUT_LENGTH = 202;
const usz MAX_LIST_LENGTH = 100;

fn void write_i32_le(char* output, usz index, int value) {
    uint bits = (uint)value;
    usz offset = index * 4;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long linkedlist_implentation_usingarray(long* input, usz length, char* output, usz output_capacity) @export("linkedlist_implentation_usingarray") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long operation_count = input[0];
    if (operation_count < 0 || operation_count > 100 || length != 1 + 2 * (usz)operation_count) return -1;
    int[MAX_LIST_LENGTH] items;
    usz item_count = 0, cursor = 1;
    for (long step = 0; step < operation_count; step += 1) {
        long opcode = input[cursor++];
        long raw_value = input[cursor++];
        if (raw_value < -2147483648 || raw_value > 2147483647 || item_count >= MAX_LIST_LENGTH) return -1;
        int value = (int)raw_value;
        if (opcode == 0) {
            usz index = item_count;
            while (index > 0) {
                items[index] = items[index - 1];
                index -= 1;
            }
            items[0] = value;
            item_count += 1;
        } else if (opcode == 1) {
            if (item_count == 0) return -1;
            items[item_count++] = value;
        } else {
            return -1;
        }
    }
    usz output_bytes = (item_count + 1) * 4;
    if (output == null || output_capacity < output_bytes) return -2;
    write_i32_le(output, 0, (int)item_count);
    for (usz index = 0; index < item_count; index += 1) write_i32_le(output, index + 1, items[index]);
    return (long)output_bytes;
}
