/// Return the first ASCII byte match using a lookahead-byte shift table.
export fn quick_search(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 512) return -1;
    if (values[0] < 0 or values[0] > 255 or values[1] < 0 or values[1] > 255) return -1;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (0..text_length + pattern_length) |index| {
        if (values[2 + index] < 0 or values[2 + index] > 127) return -1;
    }
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    var shift: [128]usize = @splat(pattern_length);
    const pattern_start = 2 + text_length;
    for (0..pattern_length) |index| {
        shift[@intCast(values[pattern_start + index])] = pattern_length - index;
    }

    var position: usize = 0;
    while (position <= text_length - pattern_length) {
        var index = pattern_length;
        while (index > 0 and values[2 + position + index - 1] == values[pattern_start + index - 1]) {
            index -= 1;
        }
        if (index == 0) return @intCast(position);
        if (position + pattern_length >= text_length) break;
        position += shift[@intCast(values[2 + position + pattern_length])];
    }
    return -1;
}
