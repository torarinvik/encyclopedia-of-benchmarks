module vigenere_cipher;

// Encrypt ASCII text with a repeating, case-insensitive Vigenere key.
fn long vigenere_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("vigenere_cipher") {
    if (length < 2 || length > 66) return -1;
    usz separator = 0;
    while (separator < length && input[separator] != 0) separator++;
    if (separator == length || separator + 1 == length) return -1;
    usz key_length = length - separator - 1;
    for (usz index = 0; index < separator; index++) {
        if (input[index] < 1 || input[index] > 127) return -1;
    }
    for (usz index = 0; index < key_length; index++) {
        long value = input[separator + 1 + index];
        if (!((value >= 65 && value <= 90) || (value >= 97 && value <= 122))) return -1;
    }
    if (output_capacity < separator) return -2;

    usz key_index = 0;
    for (usz index = 0; index < separator; index++) {
        long value = input[index];
        long mapped = value;
        if (value >= 65 && value <= 90) {
            long key_value = input[separator + 1 + key_index];
            if (key_value >= 97) key_value -= 32;
            mapped = 65 + (value - 65 + key_value - 65) % 26;
            key_index = (key_index + 1) % key_length;
        } else if (value >= 97 && value <= 122) {
            long key_value = input[separator + 1 + key_index];
            if (key_value <= 90) key_value += 32;
            mapped = 97 + (value - 97 + key_value - 97) % 26;
            key_index = (key_index + 1) % key_length;
        }
        output[index] = (char)mapped;
    }
    return (long)separator;
}
