export fn capitalize(raw: [*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (length > 256) return -1;
    if (length == 0) return 0;
    for (0..length) |i| if (raw[i] < 0 or raw[i] > 127) return -1;
    if (capacity < length) return -2;
    const out = output orelse return -2;
    for (0..length) |i| out[i] = @intCast(raw[i]);
    if (out[0] >= 'a' and out[0] <= 'z') out[0] -= 32;
    return @intCast(length);
}
