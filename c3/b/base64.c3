module base64;

fn long base64_value(long byte) {
    if (byte >= 'A' && byte <= 'Z') return byte - 'A';
    if (byte >= 'a' && byte <= 'z') return byte - 'a' + 26;
    if (byte >= '0' && byte <= '9') return byte - '0' + 52;
    if (byte == '+') return 62;
    if (byte == '/') return 63;
    return -1;
}

fn long base64(long* input, usz length, char* output, usz output_capacity) @export("base64") {
    if (length < 1 || length > 66) return -1;
    long mode = input[0];
    if (mode == 0) {
        usz count = length - 1;
        for (usz i = 1; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
        usz output_length = count == 0 ? 0 : ((count + 2) / 3) * 4;
        usz symbols = (count * 8 + 5) / 6;
        if (output_capacity < output_length) return -2;
        for (usz i = 0; i < output_length; i++) {
            if (i >= symbols) { output[i] = '='; continue; }
            long value = 0;
            for (usz bit = i * 6; bit < i * 6 + 6; bit++) {
                value = value * 2;
                if (bit < count * 8) {
                    long byte = input[1 + bit / 8];
                    value += (byte / (1L << (7 - bit % 8))) % 2L;
                }
            }
            output[i] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"[value];
        }
        return (long)output_length;
    }
    if (mode != 1) return -1;
    usz encoded_length = length - 1;
    usz content_length = encoded_length;
    for (usz i = 0; i < encoded_length; i++) if (input[i + 1] == '=') { content_length = i; break; }
    usz padding = encoded_length - content_length;
    for (usz i = 0; i < content_length; i++) if (base64_value(input[i + 1]) < 0) return -1;
    for (usz i = content_length; i < encoded_length; i++) if (input[i + 1] != '=') return -1;
    usz remainder = content_length % 4;
    usz expected_padding;
    if (remainder == 0) { expected_padding = 0; }
    else if (remainder == 2) { expected_padding = 2; }
    else if (remainder == 3) { expected_padding = 1; }
    else { return -1; }
    if (padding != 0 && (encoded_length % 4 != 0 || padding != expected_padding)) return -1;
    if (content_length != 0 && remainder != 0) {
        usz final_value = (usz)base64_value(input[content_length]);
        usz unused = remainder == 2 ? 4 : 2;
        if (final_value % ((usz)1 << unused) != 0) return -1;
    }
    usz output_length = content_length * 6 / 8;
    if (output_capacity < output_length) return -2;
    for (usz i = 0; i < output_length; i++) {
        long byte = 0;
        for (usz bit = i * 8; bit < i * 8 + 8; bit++) {
            usz symbol = (usz)base64_value(input[1 + bit / 6]);
            byte = byte * 2 + (long)((symbol / ((usz)1 << (5 - bit % 6))) % 2);
        }
        output[i] = (char)byte;
    }
    return (long)output_length;
}
