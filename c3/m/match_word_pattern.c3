module match_word_pattern;

const long MAX_PATTERN_LENGTH = 8;
const long MAX_TEXT_LENGTH = 32;
const usz MAX_INPUT_LENGTH = 43;

fn bool match_word_pattern_search(long* pattern, usz pattern_length,
                                  long* text, usz text_length,
                                  usz pattern_index, usz text_index,
                                  usz* mapped_start, usz* mapped_length) {
    if (pattern_index == pattern_length) return text_index == text_length;
    if (text_index == text_length) return false;

    usz symbol = (usz)pattern[pattern_index];
    usz known_length = mapped_length[symbol];
    if (known_length != 0) {
        if (known_length > text_length - text_index) return false;
        for (usz offset = 0; offset < known_length; offset++) {
            if (text[mapped_start[symbol] + offset] != text[text_index + offset]) return false;
        }
        return match_word_pattern_search(pattern, pattern_length, text, text_length,
                                         pattern_index + 1, text_index + known_length,
                                         mapped_start, mapped_length);
    }

    usz end = text_index + 1;
    while (end <= text_length) {
        usz candidate_length = end - text_index;
        bool already_used = false;
        usz other_index = 0;
        while (other_index < pattern_index) {
            usz other = (usz)pattern[other_index];
            if (other != symbol && mapped_length[other] == candidate_length) {
                bool equal = true;
                usz offset = 0;
                while (offset < candidate_length) {
                    if (text[mapped_start[other] + offset] != text[text_index + offset]) {
                        equal = false;
                        break;
                    }
                    offset++;
                }
                if (equal) {
                    already_used = true;
                    break;
                }
            }
            other_index++;
        }
        if (!already_used) {
            mapped_start[symbol] = text_index;
            mapped_length[symbol] = candidate_length;
            if (match_word_pattern_search(pattern, pattern_length, text, text_length,
                                          pattern_index + 1, end, mapped_start, mapped_length)) {
                return true;
            }
            mapped_length[symbol] = 0;
        }
        end++;
    }
    return false;
}

fn long match_word_pattern(long* input, usz input_length) @export("match_word_pattern") {
    if (input == null || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_PATTERN_LENGTH
        || input[1] < 0 || input[1] > MAX_TEXT_LENGTH) return -1;
    usz pattern_length = (usz)input[0];
    usz text_length = (usz)input[1];
    if (input_length != 2 + pattern_length + text_length) return -1;
    for (usz index = 0; index < pattern_length + text_length; index++) {
        if (input[2 + index] < 0 || input[2 + index] > 127) return -1;
    }

    usz[128] mapped_start = {0};
    usz[128] mapped_length = {0};
    return match_word_pattern_search(input + 2, pattern_length,
                                    input + 2 + pattern_length, text_length,
                                    0, 0, &mapped_start[0], &mapped_length[0]) ? 1 : 0;
}
