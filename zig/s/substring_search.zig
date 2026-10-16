export fn substring_search(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > 195) return -2;
    const text_length = values[0];
    const pattern_length = values[1];
    if (text_length < 0 or text_length > 128 or pattern_length < 0 or pattern_length > 64) return -2;
    if (length != 2 + @as(usize, @intCast(text_length + pattern_length))) return -2;
    const text_start: usize = 2;
    const pattern_start = text_start + @as(usize, @intCast(text_length));
    for (text_start..length) |i| if (values[i] < 1 or values[i] > 127) return -2;
    var text_index: usize = 0;
    var pattern_index: usize = 0;
    var match_start: i64 = -1;
    while (text_index < @as(usize, @intCast(text_length))) {
        const expected: i64 = if (pattern_index < @as(usize, @intCast(pattern_length)))
            values[pattern_start + pattern_index] else 0;
        if (values[text_start + text_index] == expected) {
            if (match_start == -1) match_start = @intCast(text_index);
            pattern_index += 1;
            if (pattern_index == @as(usize, @intCast(pattern_length))) return match_start;
            text_index += 1;
        } else {
            match_start = -1;
            pattern_index = 0;
            text_index += 1;
        }
    }
    return -1;
}
