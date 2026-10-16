const MAX_DIGITS: usize = 256;
const TABLE: [100]i64 = .{0, 3, 1, 7, 5, 9, 8, 6, 4, 2, 7, 0, 9, 2, 1, 5, 4, 8, 6, 3, 4, 2, 0, 6, 8, 7, 1, 3, 5, 9, 1, 7, 5, 0, 9, 8, 3, 4, 2, 6, 6, 1, 2, 3, 0, 4, 5, 9, 7, 8, 3, 6, 7, 4, 2, 0, 9, 5, 8, 1, 5, 8, 6, 9, 7, 2, 0, 1, 3, 4, 8, 9, 4, 5, 3, 6, 2, 0, 1, 7, 9, 4, 3, 8, 6, 1, 7, 2, 0, 5, 2, 5, 8, 1, 4, 3, 6, 7, 9, 0};

/// Validate a sequence or compute its appended Damm check digit.
export fn damm(input: [*]const i64, length: usize) i64 {
    if (length < 3 or length > MAX_DIGITS + 2) return -1;
    const values = input[0..length];
    const mode = values[0];
    const n = values[1];
    if ((mode != 0 and mode != 1) or n < 1 or n > MAX_DIGITS or length != @as(usize, @intCast(n)) + 2) return -1;
    var state: usize = 0;
    for (0..@intCast(n)) |index| {
        const digit = values[index + 2];
        if (digit < 0 or digit > 9) return -1;
        state = @intCast(TABLE[state * 10 + @as(usize, @intCast(digit))]);
    }
    if (mode == 0) return if (state == 0) 1 else 0;
    return @intCast(state);
}
