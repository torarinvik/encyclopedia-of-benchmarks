module base32;

fn long base32_value(long byte) {
    if (byte >= 'A' && byte <= 'Z') return byte - 'A';
    if (byte >= '2' && byte <= '7') return byte - '2' + 26;
    return -1;
}

fn long base32(long* input, usz length, char* output, usz output_capacity) @export("base32") {
    if (length < 1 || length > 66) return -1;
    long mode = input[0];
    if (mode == 0) {
        usz count = length - 1;
        for (usz i = 1; i < length; i++) if (input[i] < 0 || input[i] > 255) return -1;
        usz output_length = count == 0 ? 0 : ((count + 4) / 5) * 8;
        if (output_capacity < output_length) return -2;
        usz written = 0;
        for (usz start = 0; start < count; start += 5) {
            usz bytes = count - start < 5 ? count - start : 5;
            usz bits = bytes * 8;
            usz symbols = (bits + 4) / 5;
            for (usz symbol = 0; symbol < 8; symbol++) {
                if (symbol >= symbols) { output[written++] = '='; continue; }
                long value = 0;
                for (usz bit = symbol * 5; bit < symbol * 5 + 5; bit++) {
                    value = value * 2;
                    if (bit < bits) {
                        long byte = input[1 + start + bit / 8];
                        value += (byte / (1L << (7 - bit % 8))) % 2L;
                    }
                }
                output[written++] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"[value];
            }
        }
        return (long)output_length;
    }
    if (mode != 1) return -1;
    usz encoded_length = length - 1;
    usz content_length = encoded_length;
    for (usz i = 0; i < encoded_length; i++) if (input[i + 1] == '=') { content_length = i; break; }
    usz padding = encoded_length - content_length;
    for (usz i = 0; i < content_length; i++) if (base32_value(input[i + 1]) < 0) return -1;
    for (usz i = content_length; i < encoded_length; i++) if (input[i + 1] != '=') return -1;
    usz remainder = content_length % 8;
    usz expected_padding;
    if (remainder == 0) { expected_padding = 0; }
    else if (remainder == 2) { expected_padding = 6; }
    else if (remainder == 4) { expected_padding = 4; }
    else if (remainder == 5) { expected_padding = 3; }
    else if (remainder == 7) { expected_padding = 1; }
    else { return -1; }
    if (padding != 0 && (encoded_length % 8 != 0 || padding != expected_padding)) return -1;
    if (content_length != 0 && remainder != 0) {
        long final_value = base32_value(input[content_length]);
        usz unused = remainder == 2 ? 2 : remainder == 4 ? 4 : remainder == 5 ? 1 : 3;
        if ((final_value % (long)(1L << unused)) != 0) return -1;
    }
    usz output_length = content_length * 5 / 8;
    if (output_capacity < output_length) return -2;
    for (usz i = 0; i < output_length; i++) {
        long byte = 0;
        for (usz bit = i * 8; bit < i * 8 + 8; bit++) {
            usz symbol = (usz)base32_value(input[1 + bit / 5]);
            byte = byte * 2 + (long)((symbol / ((usz)1 << (4 - bit % 5))) % 2);
        }
        output[i] = (char)byte;
    }
    return (long)output_length;
}
