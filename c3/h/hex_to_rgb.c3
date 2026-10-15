module hex_to_rgb;

fn long hex_nibble(long value) {
    if (value >= '0' && value <= '9') return value - '0';
    if (value >= 'A' && value <= 'F') return value - 'A' + 10;
    if (value >= 'a' && value <= 'f') return value - 'a' + 10;
    return -1;
}

fn long hex_to_rgb(long* input, usz length) @export("hex_to_rgb") {
    if (input == null || length != 6) return -1;
    long packed_rgb = 0;
    for (usz index = 0; index < length; index++) {
        long nibble = hex_nibble(input[index]);
        if (nibble < 0) return -1;
        packed_rgb = (packed_rgb << 4) | nibble;
    }
    return packed_rgb;
}
