module base16;

// Encode bytes as uppercase Base16 or decode uppercase Base16 bytes.
fn long nibble(long byte) {
    if (byte >= '0' && byte <= '9') return byte - '0';
    if (byte >= 'A' && byte <= 'F') return byte - 'A' + 10;
    return -1;
}
fn long base16(long* input, usz length, char* output, usz output_capacity) @export("base16") {
    if (length < 1 || length > 65) return -1;
    long mode = input[0];
    if (mode == 0) {
        usz count = length - 1;
        usz output_length = count * 2;
        for (usz i = 1; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
        if (output_capacity < output_length) return -2;
        for (usz i = 0; i < count; i++) {
            long byte = input[i + 1];
            long high = byte / 16;
            long low = byte % 16;
            output[2 * i] = (char)(high < 10 ? '0' + high : 'A' + high - 10);
            output[2 * i + 1] = (char)(low < 10 ? '0' + low : 'A' + low - 10);
        }
        return (long)output_length;
    }
    if (mode == 1) {
        usz encoded_length = length - 1;
        if (encoded_length % 2 != 0) return -1;
        for (usz i = 1; i < length; i++) if (nibble(input[i]) < 0) return -1;
        usz output_length = encoded_length / 2;
        if (output_capacity < output_length) return -2;
        for (usz i = 0; i < output_length; i++) output[i] = (char)(nibble(input[1 + 2 * i]) * 16 + nibble(input[2 + 2 * i]));
        return (long)output_length;
    }
    return -1;
}
