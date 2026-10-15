module xor_cipher;

// XOR each input byte with a repeating key byte sequence.
fn long xor_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("xor_cipher") {
    if (length < 3 || length > 66 || input[0] < 0 || input[0] > 63 ||
        input[1] < 1 || input[1] > 63) return -1;
    usz text_length = (usz)input[0];
    usz key_length = (usz)input[1];
    if (length != 2 + text_length + key_length) return -1;
    for (usz index = 0; index < text_length + key_length; index++) {
        if (input[2 + index] < 0 || input[2 + index] > 255) return -1;
    }
    if (output_capacity < text_length) return -2;
    for (usz index = 0; index < text_length; index++) {
        output[index] = (char)(input[2 + index] ^ input[2 + text_length + index % key_length]);
    }
    return (long)text_length;
}
