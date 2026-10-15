/// Return the first pattern occurrence using a direct character-by-character scan.
const MAX_STRING_LENGTH: usize = 1024;

export fn str_str_brute_force(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > 2 + 2 * MAX_STRING_LENGTH) return -1;
    if (values[0] < 0 or values[0] > MAX_STRING_LENGTH or
        values[1] < 0 or values[1] > MAX_STRING_LENGTH) return -1;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (0..text_length + pattern_length) |index| {
        if (values[2 + index] < 1 or values[2 + index] > 127) return -1;
    }
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    const pattern_start = 2 + text_length;
    for (0..text_length - pattern_length + 1) |start| {
        var offset: usize = 0;
        while (offset < pattern_length and
               values[2 + start + offset] == values[pattern_start + offset]) : (offset += 1) {}
        if (offset == pattern_length) return @intCast(start);
    }
    return -1;
}
