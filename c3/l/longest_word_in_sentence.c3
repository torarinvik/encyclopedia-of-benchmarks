module longest_word_in_sentence;

fn bool is_ascii_whitespace(long value) {
    return value == 32 || (value >= 9 && value <= 13);
}

fn long longest_word_in_sentence(long* values, usz length, char* output, usz output_capacity)
    @export("longest_word_in_sentence") {
    if (values == null || length < 1 || values[0] < 0 || values[0] > 1024 ||
        length != 1 + (usz)values[0]) return -1;
    usz text_length = (usz)values[0];
    for (usz index = 0; index < text_length; index++) {
        long byte = values[index + 1];
        if (!is_ascii_whitespace(byte) && (byte < 33 || byte > 126)) return -1;
    }

    usz best_start = 0;
    usz best_length = 0;
    usz index = 0;
    while (index < text_length) {
        if (is_ascii_whitespace(values[index + 1])) { index++; continue; }
        usz start = index;
        while (index < text_length && !is_ascii_whitespace(values[index + 1])) index++;
        usz word_length = index - start;
        if (word_length > best_length) { best_start = start; best_length = word_length; }
    }
    if (best_length > output_capacity || (best_length > 0 && output == null)) return -2;
    for (usz byte = 0; byte < best_length; byte++) {
        output[byte] = (char)values[1 + best_start + byte];
    }
    return (long)best_length;
}
