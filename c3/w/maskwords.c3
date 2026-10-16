module maskwords;

const MAX_TEXT_BYTES: usz = 512;
const MAX_MASK_BYTES: usz = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usz = 531;
const MAX_OUTPUT_BYTES: usz = 1447;

fn bool is_word(char value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
        (value >= '0' && value <= '9') || value == '_';
}

fn bool is_normalized_target(const char* text, usz start, usz finish) {
    usz length = finish - start;
    if (length == 5) {
        return (text[start] == 'b' && text[start+1] == 'i' && text[start+2] == 'r' &&
                text[start+3] == 'd' && text[start+4] == 's') ||
               (text[start] == 'B' && text[start+1] == 'I' && text[start+2] == 'R' &&
                text[start+3] == 'D' && text[start+4] == 'S') ||
               (text[start] == 'B' && text[start+1] == 'i' && text[start+2] == 'r' &&
                text[start+3] == 'd' && text[start+4] == 's');
    }
    if (length == 6) {
        return (text[start] == 'm' && text[start+1] == 'a' && text[start+2] == 'r' &&
                text[start+3] == 'k' && text[start+4] == 'e' && text[start+5] == 't') ||
               (text[start] == 'M' && text[start+1] == 'A' && text[start+2] == 'R' &&
                text[start+3] == 'K' && text[start+4] == 'E' && text[start+5] == 'T') ||
               (text[start] == 'M' && text[start+1] == 'a' && text[start+2] == 'r' &&
                text[start+3] == 'k' && text[start+4] == 'e' && text[start+5] == 't') ||
               (text[start] == 's' && text[start+1] == 't' && text[start+2] == 'r' &&
                text[start+3] == 'e' && text[start+4] == 'e' && text[start+5] == 't') ||
               (text[start] == 'S' && text[start+1] == 'T' && text[start+2] == 'R' &&
                text[start+3] == 'E' && text[start+4] == 'E' && text[start+5] == 'T') ||
               (text[start] == 'S' && text[start+1] == 't' && text[start+2] == 'r' &&
                text[start+3] == 'e' && text[start+4] == 'e' && text[start+5] == 't');
    }
    return false;
}

fn usz match_length(const char* text, usz start, usz finish, usz position) {
    usz length = 0;
    if (position + 5 <= finish && text[position] == 'b' && text[position+1] == 'i' &&
        text[position+2] == 'r' && text[position+3] == 'd' && text[position+4] == 's') {
        length = 5;
    } else if (position + 6 <= finish && text[position] == 'm' && text[position+1] == 'a' &&
        text[position+2] == 'r' && text[position+3] == 'k' && text[position+4] == 'e' &&
        text[position+5] == 't') {
        length = 6;
    } else if (position + 6 <= finish && text[position] == 's' && text[position+1] == 't' &&
        text[position+2] == 'r' && text[position+3] == 'e' && text[position+4] == 'e' &&
        text[position+5] == 't') {
        length = 6;
    }
    if (length == 0 || (position > start && is_word(text[position-1])) ||
        (position + length < finish && is_word(text[position+length]))) return 0;
    return length;
}

fn usz append_token(const char* text, usz start, usz finish, const char* mask,
        usz mask_length, char* output, usz written_value) {
    usz written = written_value;
    if (is_normalized_target(text, start, finish)) {
        for (usz i = 0; i < mask_length; i++) { output[written] = mask[i]; written++; }
        return written;
    }
    usz position = start;
    while (position < finish) {
        usz matched = match_length(text, start, finish, position);
        if (matched != 0) {
            for (usz i = 0; i < mask_length; i++) { output[written] = mask[i]; written++; }
            position += matched;
        } else {
            if (text[position] != '\n') { output[written] = text[position]; written++; }
            position++;
        }
    }
    return written;
}

fn long maskwords(long* values, usz length, char* output, usz output_capacity)
        @export("maskwords") {
    if (values == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (values[0] < 0 || values[0] > (long)MAX_TEXT_BYTES) return -1;
    usz text_length = (usz)values[0];
    usz mask_length_index = 1 + text_length;
    if (mask_length_index >= length || values[mask_length_index] < 0 ||
        values[mask_length_index] > (long)MAX_MASK_BYTES) return -1;
    usz mask_length = (usz)values[mask_length_index];
    if (length != mask_length_index + 1 + mask_length) return -1;

    char[MAX_TEXT_BYTES] text;
    char[MAX_MASK_BYTES] mask;
    for (usz i = 0; i < text_length; i++) {
        long value = values[1+i];
        if (value < 1 || value > 127) return -1;
        text[i] = (char)value;
    }
    for (usz i = 0; i < mask_length; i++) {
        long value = values[mask_length_index+1+i];
        if (value < 32 || value > 126 || value == 92) return -1;
        mask[i] = (char)value;
    }

    char[MAX_OUTPUT_BYTES] scratch;
    usz written = 0, start = 0;
    bool have_token = false;
    for (usz i = 0; i < text_length; i++) {
        if (text[i] == ' ') {
            if (have_token) { scratch[written] = ' '; written++; }
            written = append_token(&text[0], start, i, &mask[0], mask_length,
                                   &scratch[0], written);
            have_token = true;
            start = i + 1;
        }
    }
    if (start < text_length) {
        if (have_token) { scratch[written] = ' '; written++; }
        written = append_token(&text[0], start, text_length, &mask[0], mask_length,
                               &scratch[0], written);
    }
    if (written > MAX_OUTPUT_BYTES) return -1;
    if (output_capacity < written || (written != 0 && output == null)) return -2;
    for (usz i = 0; i < written; i++) output[i] = scratch[i];
    return (long)written;
}
