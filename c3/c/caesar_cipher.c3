module caesar_cipher;

// Apply a normalized Caesar shift to ASCII letters in a byte sequence.
fn long caesar_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("caesar_cipher") {
    if (length == 0 || length > 66) return -1;
    usz text_length = length - 1;
    for (usz index = 0; index < text_length; index++) {
        if (input[index] < 0 || input[index] > 127) return -1;
    }
    if (output_capacity < text_length) return -2;

    long shift = input[text_length] % 26;
    if (shift < 0) shift += 26;
    for (usz index = 0; index < text_length; index++) {
        long value = input[index];
        long mapped = value;
        if (value >= 65 && value <= 90) {
            mapped = 65 + (value - 65 + shift) % 26;
        } else if (value >= 97 && value <= 122) {
            mapped = 97 + (value - 97 + shift) % 26;
        }
        output[index] = (char)mapped;
    }
    return (long)text_length;
}
