module gray_code;

// Emit the reflected n-bit Gray-code sequence as little-endian u32 values.
fn long gray_code(long* input, usz input_length, char* output, usz output_capacity) @export("gray_code") {
    if (input == null || input_length != 1 || input[0] < 0 || input[0] > 13) return -1;
    usz bits = input[0].usz();
    usz count = bits == 0 ? 0 : ((usz)1 << bits);
    usz required = count * 4;
    if (output == null || output_capacity < required) return -2;
    for (usz index = 0; index < count; index++) {
        u32 value = (index ^ (index >> 1)).u32();
        for (usz byte = 0; byte < 4; byte++)
            output[4 * index + byte] = (char)(value >> (8 * byte));
    }
    return count.long();
}
