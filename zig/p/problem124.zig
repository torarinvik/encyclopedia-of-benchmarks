export fn problem124(n_max: i64, k: i64) i64 {
    if (n_max < 1 or n_max > 100000 or k < 1 or k > n_max) return -1;
    const n: usize = @intCast(n_max);
    var radicals = [_]i64{0} ** 100001;
    var counts = [_]i64{0} ** 100001;
    for (1..(n + 1)) |i| radicals[i] = 1;
    for (2..(n + 1)) |p| {
        if (radicals[p] == 1) {
            var multiple = p;
            while (multiple <= n) : (multiple += p) radicals[multiple] *= @intCast(p);
        }
    }
    for (1..(n + 1)) |i| counts[@intCast(radicals[i])] += 1;
    var remaining = k;
    for (1..(n + 1)) |rad| {
        if (remaining > counts[rad]) { remaining -= counts[rad]; continue; }
        for (1..(n + 1)) |value| {
            if (radicals[value] == @as(i64, @intCast(rad))) {
                remaining -= 1;
                if (remaining == 0) return @intCast(value);
            }
        }
    }
    return -1;
}
