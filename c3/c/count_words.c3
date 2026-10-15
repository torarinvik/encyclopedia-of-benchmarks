module count_words;

const usz MAX_LENGTH = 4096;

fn bool is_trim_character(long value) { return value <= 32L; }

fn bool is_regex_whitespace(long value) {
    return value == 9L || value == 10L || value == 11L || value == 12L || value == 13L || value == 32L;
}

// Count tokens after Java String.trim() and split("\\s+").
fn long count_words(long* values, usz length) @export("count_words") {
    if (length > MAX_LENGTH || (length > 0 && values == null)) return -1L;
    for (usz i = 0; i < length; i++) if (values[i] < 0L || values[i] > 127L) return -1L;
    if (length == 0) return 0L;
    usz start = 0;
    usz end = length;
    while (start < end && is_trim_character(values[start])) start++;
    while (end > start && is_trim_character(values[end - 1])) end--;
    if (start == end) return 1L;
    long count = 0L;
    bool in_word = false;
    for (usz i = start; i < end; i++) {
        if (is_regex_whitespace(values[i])) {
            in_word = false;
        } else if (!in_word) {
            count++;
            in_word = true;
        }
    }
    return count;
}
