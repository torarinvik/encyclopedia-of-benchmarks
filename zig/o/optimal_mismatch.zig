const MAX_INPUT: usize = 274;

export fn optimal_mismatch(values_opt: ?[*]const i64, length: usize) i64 {
    if (values_opt == null or length < 2 or length > MAX_INPUT) return -2;
    const values = values_opt.?;
    if (values[0] < 0 or values[0] > 256 or values[1] < 1 or values[1] > 16) return -2;
    const n: usize = @intCast(values[0]);
    const m: usize = @intCast(values[1]);
    if (length != 2 + n + m) return -2;
    const pattern_start = 2 + n;
    for (0..n + m) |i| {
        if (values[2 + i] < 0 or values[2 + i] > 127) return -2;
    }
    if (m > n) return -1;

    var frequency = [_]usize{0} ** 128;
    for (0..n) |i| frequency[@intCast(values[2 + i])] += 1;
    var order = [_]usize{0} ** 16;
    for (0..m) |i| order[i] = i;
    for (1..m) |i| {
        const selected = order[i];
        var cursor = i;
        while (cursor > 0) {
            const previous = order[cursor - 1];
            const pf = frequency[@intCast(values[pattern_start + previous])];
            const sf = frequency[@intCast(values[pattern_start + selected])];
            if (pf < sf or (pf == sf and previous > selected)) break;
            order[cursor] = previous;
            cursor -= 1;
        }
        order[cursor] = selected;
    }

    var quick_shift = [_]usize{m + 1} ** 128;
    for (0..m) |i| quick_shift[@intCast(values[pattern_start + i])] = m - i;
    var adapted_shift = [_]usize{m} ** 16;
    for (0..m) |rank| {
        const mismatch = order[rank];
        for (1..m + 1) |shift| {
            var compatible = true;
            for (0..rank) |prior| {
                const position = order[prior];
                if (position >= shift and
                    values[pattern_start + position] != values[pattern_start + position - shift]) {
                    compatible = false;
                    break;
                }
            }
            if (!compatible) continue;
            if (mismatch >= shift and
                values[pattern_start + mismatch - shift] == values[pattern_start + mismatch]) continue;
            adapted_shift[rank] = shift;
            break;
        }
    }

    var start: usize = 0;
    const last_start = n - m;
    while (start <= last_start) {
        var rank: usize = 0;
        while (rank < m and
            values[2 + start + order[rank]] == values[pattern_start + order[rank]]) {
            rank += 1;
        }
        if (rank == m) return @intCast(start);
        if (start + m == n) break;
        const quick = quick_shift[@intCast(values[2 + start + m])];
        start += @max(adapted_shift[rank], quick);
    }
    return -1;
}
