module theoretical_rot13;

// Apply ROT13 only to lowercase non-NUL ASCII bytes.
fn long theoretical_rot13(long* input, usz length, char* output,
                           usz output_capacity) @export("theoretical_rot13") {
    if (length > 66) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 1 || input[index] > 127) return -1;
    }
    if (output_capacity < length) return -2;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        long mapped = value;
        if (value >= 'a' && value <= 'z') mapped = 'a' + (value - 'a' + 13) % 26;
        output[index] = (char)mapped;
    }
    return (long)length;
}
