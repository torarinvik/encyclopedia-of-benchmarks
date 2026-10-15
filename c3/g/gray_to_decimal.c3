module gray_to_decimal;

fn long gray_to_decimal(long* values, usz length) @export("gray_to_decimal") {
    if (length < 2 || length > 64) return -1;
    long bit_length = values[0];
    if (bit_length < 1 || bit_length > 63 || length != (usz)(bit_length + 1)) return -1;

    long prefix = 0;
    long binary = 0;
    for (usz index = 1; index < length; index++) {
        long character = values[index];
        if (character != 48 && character != 49) return -1;
        prefix ^= character - 48;
        binary = binary * 2 + prefix;
    }
    return binary;
}
