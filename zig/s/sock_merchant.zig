export fn sock_merchant(colors: [*]const i64, length: usize) i64 {
    if (length > 512) return -1;
    var counts: [4096]usize = @splat(0);
    for (0..length) |index| {
        const value = colors[index];
        if (value < 0 or value > 4095) return -1;
        counts[@intCast(value)] += 1;
    }
    var pairs: usize = 0;
    for (0..4096) |color| pairs += counts[color] / 2;
    return @intCast(pairs);
}
