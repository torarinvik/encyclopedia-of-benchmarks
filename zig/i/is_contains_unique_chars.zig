const MAX_LENGTH: usize = 4096;

export fn is_contains_unique_chars(values: ?[*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and values == null)) return -1;
    for (0..length) |index| {
        const value = values.?[index];
        if (value < 0 or value > 127) return -1;
    }

    var seen = [_]u64{0, 0};
    for (0..length) |index| {
        const value: usize = @intCast(values.?[index]);
        const word = value / 64;
        const mask = @as(u64, 1) << @intCast(value % 64);
        if ((seen[word] & mask) != 0) return 0;
        seen[word] |= mask;
    }
    return 1;
}
