export fn problem136(n_limit: i64) i64 {
    if (n_limit > 100000) return -1;
    if (n_limit <= 0) return 0;
    var solutions = [_]u8{0} ** 100000;
    const max_delta = @divTrunc(n_limit + 1, 4);
    var delta: i64 = 1;
    while (delta <= max_delta) : (delta += 1) {
        var y = 4 * delta - 1;
        while (y > delta) : (y -= 1) {
            const n = y * (4 * delta - y);
            if (n >= n_limit) break;
            const slot: usize = @intCast(n);
            if (solutions[slot] < 2) solutions[slot] += 1;
        }
    }
    var answer: i64 = 0;
    const limit: usize = @intCast(n_limit);
    for (0..limit) |n| { if (solutions[n] == 1) answer += 1; }
    return answer;
}
