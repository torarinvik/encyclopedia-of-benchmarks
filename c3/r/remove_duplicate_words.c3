module remove_duplicate_words;

const usz MAX_INPUT_LENGTH = 4096;
const usz MAX_WORDS = 2049;

fn bool is_ascii_whitespace(long byte) {
    return byte == 32 || (byte >= 9 && byte <= 13);
}

fn long remove_duplicate_words(long* values, usz length, char* output, usz output_capacity)
    @export("remove_duplicate_words") {
    if (values == null || length < 1 || values[0] < 0 || values[0] > (long)MAX_INPUT_LENGTH ||
        length != 1 + (usz)values[0]) return -1;
    usz text_length = (usz)values[0];
    for (usz index = 0; index < text_length; index++)
        if (values[index + 1] < 0 || values[index + 1] > 127) return -1;

    usz[MAX_WORDS] starts;
    usz[MAX_WORDS] word_lengths;
    usz word_count = 0;
    usz token_start = 0;
    usz output_length = 0;
    for (usz boundary = 0; boundary <= text_length; boundary++) {
        if (boundary < text_length && !is_ascii_whitespace(values[boundary + 1])) continue;
        usz word_length = boundary - token_start;
        bool duplicate = false;
        for (usz previous = 0; previous < word_count && !duplicate; previous++) {
            if (word_lengths[previous] != word_length) continue;
            usz offset = 0;
            while (offset < word_length && values[1 + starts[previous] + offset] == values[1 + token_start + offset]) offset++;
            duplicate = offset == word_length;
        }
        if (!duplicate) {
            if (word_count == MAX_WORDS) return -1;
            starts[word_count] = token_start;
            word_lengths[word_count] = word_length;
            if (word_count > 0) output_length++;
            output_length += word_length;
            word_count++;
        }
        if (boundary < text_length) token_start = boundary + 1;
    }
    if (output_length > output_capacity || (output_length > 0 && output == null)) return -2;

    usz written = 0;
    for (usz word = 0; word < word_count; word++) {
        if (word > 0) output[written++] = ' ';
        for (usz offset = 0; offset < word_lengths[word]; offset++)
            output[written++] = (char)values[1 + starts[word] + offset];
    }
    return (long)written;
}
