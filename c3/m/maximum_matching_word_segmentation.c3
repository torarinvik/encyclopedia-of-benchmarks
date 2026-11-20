module maximum_matching_word_segmentation;

const usz MAX_TEXT = 64;
const usz MAX_WORDS = 16;
const usz MAX_WORD_LENGTH = 8;
const usz MAX_INPUT_LENGTH = 210;
const usz MAX_PARSEABLE_LENGTH = 211;

fn long maximum_matching_word_segmentation(long* input, usz length, char* output, usz capacity)
    @export("maximum_matching_word_segmentation") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    long text_length_value = input[0];
    long word_count_value = input[1];
    if (text_length_value < 0 || text_length_value > (long)MAX_TEXT ||
        word_count_value < 0 || word_count_value > (long)MAX_WORDS) return -1;

    usz text_length = (usz)text_length_value;
    usz word_count = (usz)word_count_value;
    if (length < 2 + text_length) return -1;
    for (usz position = 0; position < text_length; position++) {
        if (input[2 + position] < 97 || input[2 + position] > 122) return -1;
    }

    usz[MAX_WORDS] word_offsets;
    usz[MAX_WORDS] word_lengths;
    usz cursor = 2 + text_length;
    for (usz word = 0; word < word_count; word++) {
        if (cursor >= length) return -1;
        long word_length_value = input[cursor++];
        if (word_length_value < 1 || word_length_value > (long)MAX_WORD_LENGTH) return -1;
        usz word_length = (usz)word_length_value;
        if (word_length > length - cursor) return -1;
        word_offsets[word] = cursor;
        word_lengths[word] = word_length;
        for (usz offset = 0; offset < word_length; offset++) {
            if (input[cursor + offset] < 97 || input[cursor + offset] > 122) return -1;
        }
        cursor += word_length;
    }
    if (cursor != length) return -1;

    char[MAX_TEXT] token_ids;
    usz token_count = 0;
    usz position = 0;
    while (position < text_length) {
        usz best_length = 0;
        char best_id = 0;
        for (usz word = 0; word < word_count; word++) {
            usz word_length = word_lengths[word];
            if (word_length <= best_length || word_length > text_length - position) continue;
            usz offset = 0;
            while (offset < word_length && input[word_offsets[word] + offset] == input[2 + position + offset]) offset++;
            if (offset == word_length) {
                best_length = word_length;
                best_id = (char)(word + 1);
            }
        }
        token_ids[token_count++] = best_id;
        position += best_length == 0 ? 1 : best_length;
    }

    usz output_length = token_count + 1;
    if (output == null || capacity < output_length) return -2;
    output[0] = (char)token_count;
    for (usz token = 0; token < token_count; token++) output[token + 1] = token_ids[token];
    return (long)output_length;
}
