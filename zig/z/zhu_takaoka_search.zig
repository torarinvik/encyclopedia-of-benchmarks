const max_text: usize = 256;
const max_pattern: usize = 16;
const alphabet: usize = 16;

export fn zhu_takaoka_search(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 274) return -2;
    const values = input_opt.?[0..length];
    if (values[0] < 0 or values[0] > @as(i64, @intCast(max_text)) or
        values[1] < 2 or values[1] > @as(i64, @intCast(max_pattern))) return -2;
    const n: usize = @intCast(values[0]);
    const m: usize = @intCast(values[1]);
    if (length != 2 + n + m) return -2;
    for (values[2..]) |symbol| {
        if (symbol < 0 or symbol >= @as(i64, @intCast(alphabet))) return -2;
    }
    if (m > n) return -1;

    const p = 2 + n;
    var pair_shift: [alphabet * alphabet]usize = undefined;
    for (&pair_shift) |*entry| entry.* = m;
    for (0..alphabet) |first| pair_shift[first * alphabet + @as(usize, @intCast(values[p]))] = m - 1;
    for (1..m - 1) |i| {
        pair_shift[@as(usize, @intCast(values[p + i - 1])) * alphabet +
            @as(usize, @intCast(values[p + i]))] = m - 1 - i;
    }

    var good_suffix: [max_pattern]usize = undefined;
    for (0..m) |mismatch| {
        good_suffix[mismatch] = m;
        for (1..m + 1) |shift| {
            const first_known = @max(mismatch + 1, shift);
            var position = first_known;
            while (position < m and values[p + position] == values[p + position - shift]) : (position += 1) {}
            if (position < m) continue;
            if (mismatch + 1 < m and shift <= mismatch and values[p + mismatch - shift] == values[p + mismatch]) continue;
            good_suffix[mismatch] = shift;
            break;
        }
    }

    var start: usize = 0;
    while (start <= n - m) {
        var mismatch = m;
        while (mismatch > 0 and values[p + mismatch - 1] == values[2 + start + mismatch - 1]) : (mismatch -= 1) {}
        if (mismatch == 0) return @intCast(start);
        mismatch -= 1;
        const first: usize = @intCast(values[2 + start + m - 2]);
        const second: usize = @intCast(values[2 + start + m - 1]);
        start += @max(good_suffix[mismatch], pair_shift[first * alphabet + second]);
    }
    return -1;
}
