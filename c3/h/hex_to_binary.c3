module hex_to_binary;

fn int hex_value(long value) {
    if (value >= '0' && value <= '9') return (int)(value - '0');
    if (value >= 'A' && value <= 'F') return (int)(value - 'A' + 10);
    if (value >= 'a' && value <= 'f') return (int)(value - 'a' + 10);
    return -1;
}

fn long hex_to_binary(long* values, usz length, char* output, usz capacity) @export("hex_to_binary") {
    if (length > 256 || (length != 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (hex_value(values[index]) < 0) return -1;
    }

    usz required = length * 4;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < length; index++) {
        int digit = hex_value(values[index]);
        for (usz bit = 0; bit < 4; bit++) {
            output[index * 4 + bit] = (char)('0' + ((digit >> (3 - (int)bit)) & 1));
        }
    }
    return (long)required;
}
