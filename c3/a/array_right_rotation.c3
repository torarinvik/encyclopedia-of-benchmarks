module array_right_rotation;

const usz MAX_ARRAY_LENGTH = 1024;
const usz MAX_INPUT_LENGTH = 1025;
const long MAX_SHIFT = 1024;

fn void write_i32_le(char* output, usz index, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte++) {
        output[index * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
    }
}

// Return a new right-rotated array; shifts at least as large as its length yield empty output.
fn long array_right_rotation(long* input, usz length, char* output, usz output_capacity) @export("array_right_rotation") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) { return -1; }
    long shift_value = input[0];
    if (shift_value < 0 || shift_value > MAX_SHIFT) { return -1; }
    usz count = length - 1;
    long[MAX_ARRAY_LENGTH] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -2147483648L || value > 2147483647L) { return -1; }
        values[index] = value;
    }
    usz shift = (usz)shift_value;
    if (shift >= count) { return 0; }
    usz output_bytes = count * 4;
    if (output_capacity < output_bytes || output == null) { return -2; }
    for (usz index = 0; index < shift; index++) {
        write_i32_le(output, index, values[count - shift + index]);
    }
    for (usz index = shift; index < count; index++) {
        write_i32_le(output, index, values[index - shift]);
    }
    return (long)count;
}
