module rot13;

// Apply case-preserving ROT13 to a non-NUL ASCII byte sequence.
fn long rot13(long* input, usz length, char* output, usz output_capacity) @export("rot13") {
    if (length > 66) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 1 || input[index] > 127) return -1;
    }
    if (output_capacity < length) return -2;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        long mapped = value;
        if (value >= 'A' && value <= 'Z') {
            mapped = 'A' + (value - 'A' + 13) % 26;
        } else if (value >= 'a' && value <= 'z') {
            mapped = 'a' + (value - 'a' + 13) % 26;
        }
        output[index] = (char)mapped;
    }
    return (long)length;
}
