/// Direct recursive full-string matching for the . and * regular-expression subset.
fn regexMatchRecursive(values: []const i64, text_length: usize, pattern_start: usize,
    pattern_length: usize, text_index: usize, pattern_index: usize) bool {
    if (pattern_index == pattern_length) return text_index == text_length;
    const atom = values[pattern_start + pattern_index];
    if (pattern_index + 1 < pattern_length and values[pattern_start + pattern_index + 1] == '*') {
        if (regexMatchRecursive(values, text_length, pattern_start, pattern_length,
            text_index, pattern_index + 2)) return true;
        return text_index < text_length and (atom == '.' or atom == values[2 + text_index]) and
            regexMatchRecursive(values, text_length, pattern_start, pattern_length,
                text_index + 1, pattern_index);
    }
    return text_index < text_length and (atom == '.' or atom == values[2 + text_index]) and
        regexMatchRecursive(values, text_length, pattern_start, pattern_length,
            text_index + 1, pattern_index + 1);
}

export fn regex_match(raw_values: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const values = raw_values[0..length];
    if (values[0] < 0 or values[0] > 12 or values[1] < 0 or values[1] > 20) return -1;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    const pattern_start = 2 + text_length;
    for (values[2..pattern_start]) |symbol| {
        if (symbol < 'a' or symbol > 'z') return -1;
    }
    for (0..pattern_length) |index| {
        const symbol = values[pattern_start + index];
        if (!((symbol >= 'a' and symbol <= 'z') or symbol == '.' or symbol == '*')) return -1;
        if (symbol == '*' and (index == 0 or values[pattern_start + index - 1] == '*')) return -1;
    }
    return if (regexMatchRecursive(values, text_length, pattern_start, pattern_length, 0, 0)) 1 else 0;
}
