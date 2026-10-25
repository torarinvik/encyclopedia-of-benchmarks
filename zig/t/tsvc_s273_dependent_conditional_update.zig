const max_n: usize = 64;
const max_passes: usize = 8;

export fn tsvc_s273_dependent_conditional_update(values_opt: ?[*]const i64, length: usize) i64 {
    if (values_opt == null or length < 7 or length > 2 + 5 * max_n) return -1;
    const values = values_opt.?;
    const n_value = values[0];
    const passes_value = values[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n))
        or passes_value < 1 or passes_value > @as(i64, @intCast(max_passes))) return -1;
    const n: usize = @intCast(n_value);
    const passes: usize = @intCast(passes_value);
    if (length != 2 + 5 * n) return -1;
    for (2..length) |index| {
        if (values[index] < -2 or values[index] > 2) return -1;
    }

    var a: [max_n]i64 = [_]i64{0} ** max_n;
    var b: [max_n]i64 = [_]i64{0} ** max_n;
    var c: [max_n]i64 = [_]i64{0} ** max_n;
    var d: [max_n]i64 = [_]i64{0} ** max_n;
    var e: [max_n]i64 = [_]i64{0} ** max_n;
    for (0..n) |i| {
        a[i] = values[2 + i];
        b[i] = values[2 + n + i];
        c[i] = values[2 + 2 * n + i];
        d[i] = values[2 + 3 * n + i];
        e[i] = values[2 + 4 * n + i];
    }
    for (0..passes) |_| {
        for (0..n) |i| {
            a[i] += d[i] * e[i];
            if (a[i] < 0) b[i] += d[i] * e[i];
            c[i] += a[i] * d[i];
        }
    }
    var checksum: i64 = 0;
    for (0..n) |i| checksum += a[i] + b[i] + c[i];
    return checksum;
}
