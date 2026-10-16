module substring_search;

fn long substring_search(long* values, usz length) @export("substring_search") {
    if (values == null || length < 2 || length > 195) return -2;
    long text_length = values[0], pattern_length = values[1];
    if (text_length < 0 || text_length > 128 || pattern_length < 0 || pattern_length > 64 ||
        length != (usz)(2 + text_length + pattern_length)) return -2;
    usz text_start = 2, pattern_start = text_start + (usz)text_length;
    for (usz i = text_start; i < length; i++) if (values[i] < 1 || values[i] > 127) return -2;
    usz text_index = 0, pattern_index = 0;
    long match_start = -1;
    while (text_index < (usz)text_length) {
        long expected = pattern_index < (usz)pattern_length ? values[pattern_start + pattern_index] : 0;
        if (values[text_start + text_index] == expected) {
            if (match_start == -1) match_start = (long)text_index;
            pattern_index++;
            if (pattern_index == (usz)pattern_length) return match_start;
            text_index++;
        } else {
            match_start = -1;
            pattern_index = 0;
            text_index++;
        }
    }
    return -1;
}
