pub export fn tsvc_s331_last_negative_index(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > 257) return -1;
    const n = values[0];
    if (n < 1 or n > 256 or length != 1 + @as(usize, @intCast(n))) return -1;
    var result: i64 = 0;
    for (0..@as(usize, @intCast(n))) |i| {
        const value = values[1 + i];
        if (value < -1_000_000 or value > 1_000_000) return -1;
        if (value < 0) result = @intCast(i + 1);
    }
    return result;
}
