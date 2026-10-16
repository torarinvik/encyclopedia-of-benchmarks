fn insertionSort(q: *[5]f64, n: usize) void {
    for (1..n) |i| {
        const x = q[i];
        var j = i;
        while (j > 0 and q[j - 1] > x) : (j -= 1) q[j] = q[j - 1];
        q[j] = x;
    }
}

export fn p2_quantile_estimator(v: [*]const i64, n: usize) f64 {
    if (n < 2 or n > 65 or v[0] < 1 or v[0] > 64 or n != @as(usize, @intCast(v[0])) + 1) return -1e300;
    const count: usize = @intCast(v[0]);
    var q = [_]f64{0} ** 5;
    var pos = [_]f64{0} ** 5;
    var desired = [_]f64{0} ** 5;
    const increments = [_]f64{ 0, 0.25, 0.5, 0.75, 1 };
    var seen: usize = 0;
    for (0..count) |z| {
        if (v[z + 1] < -2147483648 or v[z + 1] > 2147483647) return -1e300;
        const x = @as(f64, @floatFromInt(v[z + 1]));
        if (seen < 5) {
            q[seen] = x;
            seen += 1;
            if (seen == 5) {
                insertionSort(&q, 5);
                for (0..5) |i| { pos[i] = @floatFromInt(i + 1); desired[i] = @floatFromInt(i + 1); }
            }
            continue;
        }
        var cell: usize = 3;
        if (x < q[0]) { q[0] = x; cell = 0; } else {
            for (1..4) |i| { if (x < q[i]) { cell = i - 1; break; } }
            if (x > q[4]) q[4] = x;
        }
        for (cell + 1..5) |i| pos[i] += 1;
        for (0..5) |i| desired[i] += increments[i];
        for (1..4) |i| {
            const drift = desired[i] - pos[i];
            const right = drift >= 1 and pos[i + 1] - pos[i] > 1;
            const left = drift <= -1 and pos[i - 1] - pos[i] < -1;
            if (!right and !left) continue;
            const direction: f64 = if (right) 1 else -1;
            const l = pos[i] - pos[i - 1];
            const r = pos[i + 1] - pos[i];
            const candidate = q[i] + direction / (l + r) * ((l + direction) * (q[i + 1] - q[i]) / r + (r - direction) * (q[i] - q[i - 1]) / l);
            if (q[i - 1] < candidate and candidate < q[i + 1]) q[i] = candidate else {
                const neighbor: usize = @intCast(@as(isize, @intCast(i)) + @as(isize, @intFromFloat(direction)));
                q[i] += direction * (q[neighbor] - q[i]) / (pos[neighbor] - pos[i]);
            }
            pos[i] += direction;
        }
    }
    if (seen < 5) {
        insertionSort(&q, count);
        const rank = 0.5 * @as(f64, @floatFromInt(count - 1));
        const lower: usize = @intFromFloat(rank);
        const upper = @min(lower + 1, count - 1);
        return q[lower] + (rank - @as(f64, @floatFromInt(lower))) * (q[upper] - q[lower]);
    }
    return q[2];
}
