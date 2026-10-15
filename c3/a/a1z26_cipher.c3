module a1z26_cipher;

// Encode ASCII letters as their one-based alphabet positions.
fn long a1z26_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("a1z26_cipher") {
    if (length > 66) return -1;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        if (!((value >= 65 && value <= 90) || (value >= 97 && value <= 122))) return -1;
    }
    if (output_capacity < length) return -2;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        output[index] = (char)(value >= 97 ? value - 96 : value - 64);
    }
    return (long)length;
}
