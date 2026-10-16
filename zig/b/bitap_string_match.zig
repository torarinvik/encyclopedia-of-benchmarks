const MAX_TEXT_LENGTH: i64 = 4096;
const MAX_PATTERN_LENGTH: i64 = 63;

pub export fn bitap_string_match(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2) return -2;
    if (values[0] < 0 or values[0] > MAX_TEXT_LENGTH or
        values[1] < 0 or values[1] > MAX_PATTERN_LENGTH) return -2;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -2;
    for (2..length) |index| {
        if (values[index] < 97 or values[index] > 122) return -2;
    }
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    var masks: [26]u64 = @splat(~@as(u64, 0));
    for (0..pattern_length) |index| {
        const letter: usize = @intCast(values[2 + text_length + index] - 97);
        masks[letter] &= ~(@as(u64, 1) << @as(u6, @intCast(index)));
    }
    var state: u64 = ~@as(u64, 1);
    for (0..text_length) |index| {
        const letter: usize = @intCast(values[2 + index] - 97);
        state |= masks[letter];
        state <<= 1;
        if (state & (@as(u64, 1) << @as(u6, @intCast(pattern_length))) == 0)
            return @as(i64, @intCast(index)) - @as(i64, @intCast(pattern_length)) + 1;
    }
    return -1;
}
