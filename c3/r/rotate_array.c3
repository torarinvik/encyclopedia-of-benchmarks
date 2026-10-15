module rotate_array;

const usz MAX_ARRAY_LENGTH = 1024;
const usz MAX_INPUT_LENGTH = 1025;
const long MAX_ROTATIONS = 1024;

// Rotate an array right by repeating a one-place shift.
fn long rotate_array(long* input, usz length, char* output, usz output_capacity) @export("rotate_array") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) { return -1; }
    long rotations = input[0];
    if (rotations < 0 || rotations > MAX_ROTATIONS) { return -1; }
    usz count = length - 1;
    long[MAX_ARRAY_LENGTH] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -2147483648L || value > 2147483647L) { return -1; }
        values[index] = value;
    }
    usz output_bytes = count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) { return -2; }
    for (long step = 0; step < rotations && count > 1; step++) {
        long last = values[count - 1];
        for (usz index = count - 1; index > 0; index--) { values[index] = values[index - 1]; }
        values[0] = last;
    }
    for (usz index = 0; index < count; index++) {
        uint bits = (uint)(int)values[index];
        for (usz byte = 0; byte < 4; byte++) {
            output[index * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
    }
    return (long)count;
}
