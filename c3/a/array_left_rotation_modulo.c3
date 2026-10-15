module array_left_rotation_modulo;

const usz MAX_ARRAY_LENGTH = 1024;
const usz MAX_INPUT_LENGTH = 1025;

fn void write_i32_le(char* output, usz index, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte++) {
        output[index * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
    }
}

// Return a fresh left rotation; nonpositive shifts keep the input order and positive shifts wrap.
fn long array_left_rotation_modulo(long* input, usz length, char* output, usz output_capacity) @export("array_left_rotation_modulo") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long rotations = input[0];
    if (rotations < -2147483648L || rotations > 2147483647L) return -1;
    usz count = length - 1;
    long[MAX_ARRAY_LENGTH] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -2147483648L || value > 2147483647L) return -1;
        values[index] = value;
    }
    if (count == 0) return 0;
    usz shift = rotations > 0 ? (usz)(rotations % (long)count) : 0;
    usz output_bytes = count * 4;
    if (output_capacity < output_bytes || output == null) return -2;
    for (usz index = shift; index < count; index++) write_i32_le(output, index - shift, values[index]);
    for (usz index = 0; index < shift; index++) write_i32_le(output, count - shift + index, values[index]);
    return (long)count;
}

