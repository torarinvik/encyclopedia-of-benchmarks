module count_substrings;

const usz MAX_LENGTH = 4096;

fn long find_next(long* values, usz text_length, usz pattern_length, usz pattern_start, usz start) {
    if (start > text_length || pattern_length > text_length - start) return -1;
    usz last = text_length - pattern_length;
    for (usz position = start; position <= last; position++) {
        usz offset = 0;
        while (offset < pattern_length && values[2 + position + offset] == values[pattern_start + offset]) offset++;
        if (offset == pattern_length) return (long)position;
    }
    return -1;
}

fn long count_substrings(long* values, usz length) @export("count_substrings") {
    if (values == null || length < 2 || values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 4096) return -1;
    usz text_length = (usz)values[0], pattern_length = (usz)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz i = 2; i < length; i++) if (values[i] < 0 || values[i] > 127) return -1;
    if (pattern_length == 0) return (long)text_length + 1;
    usz pattern_start = 2 + text_length;
    long count = 0;
    long position = find_next(values, text_length, pattern_length, pattern_start, 0);
    while (position >= 0) {
        count++;
        position = find_next(values, text_length, pattern_length, pattern_start, (usz)position + 1);
    }
    return count;
}
