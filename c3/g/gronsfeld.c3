module gronsfeld;

// Encrypt ASCII letters with a repeating decimal-digit Gronsfeld key.
fn long gronsfeld(long* input, usz length, char* output, usz output_capacity)
        @export("gronsfeld") {
    if (input == null || length < 2 || length > 321) return -1;
    usz separator = 0;
    while (separator < length && input[separator] != 0) separator++;
    if (separator == length) return -1;
    usz text_length = separator;
    usz key_length = length - separator - 1;
    if (text_length > 256 || key_length < 1 || key_length > 64) return -1;

    for (usz index = 0; index < text_length; index++) {
        if (input[index] < 1 || input[index] > 127) return -1;
    }
    for (usz index = 0; index < key_length; index++) {
        long value = input[separator + 1 + index];
        if (value < 48 || value > 57) return -1;
    }
    if (output_capacity < text_length || (text_length > 0 && output == null)) return -2;

    usz key_index = 0;
    for (usz index = 0; index < text_length; index++) {
        long value = input[index];
        long mapped = value;
        if (value >= 65 && value <= 90) {
            long shift = input[separator + 1 + key_index % key_length] - 48;
            mapped = 65 + (value - 65 + shift) % 26;
            key_index++;
        } else if (value >= 97 && value <= 122) {
            long shift = input[separator + 1 + key_index % key_length] - 48;
            mapped = 97 + (value - 97 + shift) % 26;
            key_index++;
        }
        output[index] = (char)mapped;
    }
    return (long)text_length;
}
