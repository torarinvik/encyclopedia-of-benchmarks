module wave_string;

const usz MAX_TEXT_LENGTH = 512;

fn bool is_ascii_letter(long value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

fn long wave_string(long* values, usz length, char* output, usz output_capacity)
    @export("wave_string") {
    if (values == null || length < 1 || values[0] < 0 || values[0] > (long)MAX_TEXT_LENGTH ||
        length != 1 + (usz)values[0]) return -1;
    usz text_length = (usz)values[0];
    usz letter_count = 0;
    for (usz index = 0; index < text_length; index++) {
        long byte = values[index + 1];
        if (byte < 32 || byte > 126) return -1;
        if (is_ascii_letter(byte)) letter_count++;
    }
    usz output_length = letter_count * (text_length + 2);
    if (output_length > output_capacity || (output_length > 0 && output == null)) return -2;

    usz written = 0;
    for (usz position = 0; position < text_length; position++) {
        if (!is_ascii_letter(values[position + 1])) continue;
        output[written++] = (char)(text_length & 255);
        output[written++] = (char)(text_length >> 8);
        for (usz index = 0; index < text_length; index++) {
            long byte = values[index + 1];
            if (index == position && byte >= 'a' && byte <= 'z') byte -= 32;
            output[written++] = (char)byte;
        }
    }
    return (long)letter_count;
}
