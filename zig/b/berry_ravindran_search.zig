const MAX_INPUT: usize = 274;

export fn berry_ravindran_search(values_opt: ?[*]const i64, length: usize) i64 {
    if (values_opt == null or length < 2 or length > MAX_INPUT) return -2;
    const values = values_opt.?;
    if (values[0] < 0 or values[0] > 256 or values[1] < 1 or values[1] > 16) return -2;
    const n: usize = @intCast(values[0]);
    const m: usize = @intCast(values[1]);
    if (length != 2 + n + m) return -2;
    for (0..n + m) |i| {
        if (values[2 + i] < 0 or values[2 + i] > 15) return -2;
    }
    if (m > n) return -1;
    const p = 2 + n;
    var shift = [_]usize{m + 2} ** 289;
    for (0..17) |first| shift[first * 17 + @intCast(values[p])] = m + 1;
    for (0..(m - 1)) |i| shift[@intCast(values[p + i]) * 17 + @intCast(values[p + i + 1])] = m - i;
    for (0..17) |second| shift[@intCast(values[p + m - 1]) * 17 + second] = 1;
    var start: usize = 0;
    while (start <= n - m) {
        var i: usize = 0;
        while (i < m and values[2 + start + i] == values[p + i]) : (i += 1) {}
        if (i == m) return @intCast(start);
        const k = start + m;
        if (k >= n) break;
        const first: usize = @intCast(values[2 + k]);
        const second: usize = if (k + 1 < n) @intCast(values[2 + k + 1]) else 16;
        start += shift[first * 17 + second];
    }
    return -1;
}
