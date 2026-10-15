module gronsfeld_cipher;

// Encrypt 7-bit ASCII with a repeating decimal-digit Gronsfeld key.
fn long gronsfeld_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("gronsfeld_cipher") {
    if (length < 1 || length > 321) return -1;
    usz separator = 0;
    while (separator < length && input[separator] != 0) separator++;
    if (separator == length) return -1;
    usz text_length = separator;
    usz key_length = length - separator - 1;
    if (text_length > 256 || key_length > 64) return -1;

    for (usz index = 0; index < text_length; index++) {
        if (input[index] < 1 || input[index] > 127) return -1;
    }
    for (usz index = 0; index < key_length; index++) {
        long value = input[separator + 1 + index];
        if (value < 48 || value > 57) return -1;
    }
    if (key_length == 0) {
        for (usz index = 0; index < text_length; index++) {
            long value = input[index];
            if ((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) return -1;
        }
    }
    if (output_capacity < text_length) return -2;

    for (usz index = 0; index < text_length; index++) {
        long value = input[index];
        long mapped = value;
        if (value >= 65 && value <= 90) {
            long shift = input[separator + 1 + index % key_length] - 48;
            mapped = 65 + (value - 65 + shift) % 26;
        } else if (value >= 97 && value <= 122) {
            long shift = input[separator + 1 + index % key_length] - 48;
            mapped = 65 + (value - 97 + shift) % 26;
        }
        output[index] = (char)mapped;
    }
    return (long)text_length;
}
