module count_sentences;

const usz MAX_TEXT_LENGTH = 4096;

fn bool is_trim_byte(char value) {
    return value == 0 || value == 9 || value == 10 || value == 11 || value == 13 || value == 32;
}

fn bool is_regex_space(char value) {
    return (value >= 9 && value <= 13) || value == 32;
}

fn bool is_word_byte(char value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
        (value >= '0' && value <= '9') || value == '_';
}

fn bool is_terminator(char value) {
    return value == '.' || value == '!' || value == '?';
}

fn bool is_eligible_predecessor(char value) {
    return !is_regex_space(value) && value != '|' && value != '^' && value != '.';
}

fn long count_sentences(long* input, usz length) @export("count_sentences") {
    if (input == null || length < 1 || length > MAX_TEXT_LENGTH + 1 ||
        input[0] < 0 || input[0] > (long)MAX_TEXT_LENGTH || length != (usz)input[0] + 1) return -1;
    usz text_length = (usz)input[0];
    char[MAX_TEXT_LENGTH] text;
    for (usz index = 0; index < text_length; index++) {
        if (input[index + 1] < 0 || input[index + 1] > 127) return -1;
        text[index] = (char)input[index + 1];
    }

    usz begin = 0, end = text_length;
    while (begin < end && is_trim_byte(text[begin])) begin++;
    while (end > begin && is_trim_byte(text[end - 1])) end--;
    usz cursor = begin;
    long count = 0;
    while (cursor + 1 < end) {
        bool found = false;
        for (usz index = cursor; index + 1 < end; index++) {
            if (is_eligible_predecessor(text[index]) && is_terminator(text[index + 1]) &&
                (index + 2 == end || !is_word_byte(text[index + 2]))) {
                count++;
                cursor = index + 2;
                found = true;
                break;
            }
        }
        if (!found) break;
    }
    return count;
}
