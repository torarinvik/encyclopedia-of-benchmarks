module not_so_naive_search;

const int MAX_TEXT = 512, MIN_PATTERN = 2, MAX_PATTERN = 64, MAX_INPUT = 578;

long not_so_naive_search(long* values, usz length) @export("not_so_naive_search") {
    if (values == null || length < 2 || length > MAX_INPUT) return -2;
    long text_length_raw = values[0], pattern_length_raw = values[1];
    if (text_length_raw < 0 || text_length_raw > MAX_TEXT ||
        pattern_length_raw < MIN_PATTERN || pattern_length_raw > MAX_PATTERN) return -2;
    usz text_length = (usz)text_length_raw, pattern_length = (usz)pattern_length_raw;
    if (length != 2 + text_length + pattern_length) return -2;
    usz pattern_start = 2 + text_length;
    for (usz i = 0; i < text_length + pattern_length; i++)
        if (values[2 + i] < 0 || values[2 + i] > 127) return -2;
    if (pattern_length > text_length) return -1;

    bool same_prefix = values[pattern_start] == values[pattern_start + 1];
    usz mismatch_shift = same_prefix ? 2 : 1;
    usz post_check_shift = same_prefix ? 1 : 2;
    usz position = 0, last_start = text_length - pattern_length;
    while (position <= last_start) {
        if (values[pattern_start + 1] != values[2 + position + 1]) {
            position += mismatch_shift;
            continue;
        }
        usz pattern_index = 2;
        while (pattern_index < pattern_length &&
               values[pattern_start + pattern_index] == values[2 + position + pattern_index])
            pattern_index++;
        if (pattern_index == pattern_length && values[pattern_start] == values[2 + position])
            return (long)position;
        position += post_check_shift;
    }
    return -1;
}
