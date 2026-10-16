module max_word;

const usz MAX_TEXT_LENGTH = 512;
const usz MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2;

fn u8 lower_ascii(u8 value) {
    if (value >= 'A' && value <= 'Z') { return value + ('a' - 'A'); }
    return value;
}

fn long max_word(long* input, usz length, u8* output, usz output_capacity)
    @export("max_word")
{
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) { return -1; }
    long text_length_value = input[0];
    if (text_length_value < 1 || text_length_value > (long)MAX_TEXT_LENGTH ||
        length != 1 + (usz)text_length_value) { return -1; }
    usz text_length = (usz)text_length_value;
    u8[MAX_TEXT_LENGTH] text;
    for (usz i = 0; i < text_length; i++) {
        long value = input[i + 1];
        bool is_letter = (value >= 65 && value <= 90) || (value >= 97 && value <= 122);
        if (value == 32) {
            if (i == 0 || i + 1 == text_length || text[i - 1] == 32) { return -1; }
        } else if (!is_letter || value == 73) {
            return -1;
        }
        text[i] = (u8)value;
    }

    usz[MAX_TEXT_LENGTH] starts;
    usz[MAX_TEXT_LENGTH] lengths;
    usz[MAX_TEXT_LENGTH] counts;
    usz unique_count = 0;
    usz start = 0;
    while (start < text_length) {
        usz end = start;
        while (end < text_length && text[end] != 32) { end++; }
        usz word_length = end - start;
        if (word_length > 6) { return -1; }
        usz found = unique_count;
        for (usz key = 0; key < unique_count; key++) {
            if (lengths[key] != word_length) { continue; }
            usz offset = 0;
            while (offset < word_length &&
                lower_ascii(text[starts[key] + offset]) == lower_ascii(text[start + offset])) { offset++; }
            if (offset == word_length) { found = key; break; }
        }
        if (found == unique_count) {
            starts[unique_count] = start;
            lengths[unique_count] = word_length;
            counts[unique_count] = 1;
            unique_count++;
        } else {
            counts[found]++;
        }
        start = end + 1;
    }

    usz winner = 0;
    for (usz key = 1; key < unique_count; key++) {
        if (counts[key] > counts[winner]) { winner = key; }
    }
    usz result_length = lengths[winner];
    if (output_capacity < result_length || output == null) { return -2; }
    bool single_word = unique_count == 1 && counts[0] == 1;
    for (usz i = 0; i < result_length; i++) {
        u8 value = text[starts[winner] + i];
        output[i] = single_word ? value : lower_ascii(value);
    }
    return (long)result_length;
}
