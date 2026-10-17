module tbc_padding;

const usz MAX_BYTES = 256;

fn void write_i64_le(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[position + byte] = (char)(bits >> (8 * byte));
}

fn long tbc_padding(long* input, usz length, char* output, usz capacity) @export("tbc_padding") {
    if (input == null || length < 3 || length > MAX_BYTES + 3) return -1;
    long operation = input[0], offset_value = input[1], count_value = input[2];
    if (operation < 0 || operation > 2 || count_value < 0 || count_value > (long)MAX_BYTES ||
        length != (usz)count_value + 3) return -1;
    usz count = (usz)count_value;
    if ((operation == 0 && (count == 0 || offset_value < 0 || offset_value > count_value)) ||
        (operation != 0 && offset_value != 0) || (operation == 2 && count == 0)) return -1;
    for (usz i = 0; i < count; i++) if (input[3 + i] < 0 || input[3 + i] > 255) return -1;

    if (operation == 0) {
        usz offset = (usz)offset_value;
        long previous = input[offset > 0 ? offset + 2 : count + 2];
        char code = (previous & 1) == 0 ? (char)0xff : (char)0;
        usz needed = 8 + count;
        if (output == null || capacity < needed) return -2;
        write_i64_le(output, 0, (long)(count - offset));
        for (usz i = 0; i < count; i++) output[8 + i] = i >= offset ? code : (char)input[3 + i];
        return (long)needed;
    }
    if (operation == 1) {
        usz survivors = count;
        long code = 0;
        if (count > 0) {
            code = (input[2 + count] & 1) == 0 ? 0 : 255;
            while (survivors > 0 && input[2 + survivors] == code) survivors--;
        }
        if (output == null || capacity < survivors) return -2;
        for (usz i = 0; i < survivors; i++) output[i] = (char)input[3 + i];
        return (long)survivors;
    }
    long terminal = input[2 + count];
    if (terminal != 0 && terminal != 255) return -1;
    usz padding_count = 0;
    while (padding_count < count && input[2 + count - padding_count] == terminal) padding_count++;
    if (output == null || capacity < 8) return -2;
    write_i64_le(output, 0, (long)padding_count);
    return 8;
}
