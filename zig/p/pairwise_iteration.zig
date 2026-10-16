export fn pairwise_iteration(v: [*c]const i64, n: usize, out: [*c]u8, cap: usize) i64 {
    if (v == null or n < 1 or n > 129 or v[0] < 0 or v[0] > 128 or n != @as(usize, @intCast(v[0])) + 1) return -1;
    const count: usize = @intCast(v[0]);
    for (0..count) |i| if (v[i + 1] < -1000000 or v[i + 1] > 1000000) return -1;
    const bytes = count -| 1;
    const needed = bytes * 16;
    if (needed > cap or (needed > 0 and out == null)) return -2;
    var k: usize = 0;
    for (0..bytes) |i| {
        for (0..2) |j| {
            const x: u64 = @bitCast(v[i + j + 1]);
            for (0..8) |b| { out[k] = @truncate(x >> @as(u6, @intCast(8 * b))); k += 1; }
        }
    }
    return @intCast(needed);
}
