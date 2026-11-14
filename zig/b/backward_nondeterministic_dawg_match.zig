pub export fn backward_nondeterministic_dawg_match(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or values[0] < 0 or values[0] > 4096 or values[1] < 0 or values[1] > 63) return -2;
    const n: usize = @intCast(values[0]);
    const m: usize = @intCast(values[1]);
    if (length != 2 + n + m) return -2;
    for (2..length) |i| {
        if (values[i] < 97 or values[i] > 122) return -2;
    }
    if (m == 0) return 0;
    if (m > n) return -1;
    var masks: [26]u64 = @splat(0);
    for (0..m) |i| {
        const letter: usize = @intCast(values[2 + n + i] - 97);
        masks[letter] |= @as(u64, 1) << @as(u6, @intCast(m - 1 - i));
    }
    var start: usize = 0;
    while (start <= n - m) {
        var remaining = m;
        var shift = m;
        var states: u64 = ~@as(u64, 0);
        while (remaining > 0 and states != 0) {
            remaining -= 1;
            const letter: usize = @intCast(values[2 + start + remaining] - 97);
            states &= masks[letter];
            if (states != 0) {
                if (remaining == 0) return @intCast(start);
                shift = remaining;
            }
            states <<= 1;
        }
        start += shift;
    }
    return -1;
}
