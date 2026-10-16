const std = @import("std");

const MAX_TEXT_LENGTH: i64 = 4096;
const MAX_PATTERN_LENGTH: i64 = 31;

export fn bitap_exact_match_31(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2) return -2;
    if (values[0] < 0 or values[0] > MAX_TEXT_LENGTH or values[1] < 0 or values[1] > MAX_PATTERN_LENGTH) return -2;
    const text_length: usize = @intCast(values[0]);
    const pattern_length: usize = @intCast(values[1]);
    if (length != 2 + text_length + pattern_length) return -2;
    for (2..length) |i| if (values[i] < 97 or values[i] > 122) return -2;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;
    var masks = [_]u32{std.math.maxInt(u32)} ** 26;
    for (0..pattern_length) |i| {
        const letter: usize = @intCast(values[2 + text_length + i] - 97);
        masks[letter] &= ~(@as(u32, 1) << @intCast(i));
    }
    var state: u32 = ~@as(u32, 1);
    for (0..text_length) |i| {
        const letter: usize = @intCast(values[2 + i] - 97);
        state |= masks[letter];
        state <<= 1;
        if (state & (@as(u32, 1) << @intCast(pattern_length)) == 0) return @as(i64, @intCast(i)) - @as(i64, @intCast(pattern_length)) + 1;
    }
    return -1;
}
