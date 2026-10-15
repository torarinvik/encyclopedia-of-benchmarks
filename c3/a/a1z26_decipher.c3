module a1z26_decipher;

// Decode one-based alphabet positions as lowercase ASCII letters.
fn long a1z26_decipher(long* input, usz length, char* output, usz output_capacity)
        @export("a1z26_decipher") {
    if (length > 66) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < 1 || input[index] > 26) return -1;
    }
    if (output_capacity < length) return -2;
    for (usz index = 0; index < length; index++) output[index] = (char)(96 + input[index]);
    return (long)length;
}
