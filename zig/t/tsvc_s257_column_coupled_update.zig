const max_n: usize = 8;
const max_passes: usize = 4;

export fn tsvc_s257_column_coupled_update(values_opt: ?[*]const i64, length: usize) i64 {
    if (values_opt == null or length < 12 or length > 2 + max_n + 2 * max_n * max_n) return -1;
    const values = values_opt.?;
    const n_value = values[0];
    const passes_value = values[1];
    if (n_value < 2 or n_value > @as(i64, @intCast(max_n))
        or passes_value < 1 or passes_value > @as(i64, @intCast(max_passes))) return -1;
    const n: usize = @intCast(n_value);
    const passes: usize = @intCast(passes_value);
    if (length != 2 + n + 2 * n * n) return -1;
    for (2..length) |index| {
        if (values[index] < -1 or values[index] > 1) return -1;
    }

    var a: [max_n]i64 = [_]i64{0} ** max_n;
    var aa: [max_n * max_n]i64 = [_]i64{0} ** (max_n * max_n);
    var bb: [max_n * max_n]i64 = [_]i64{0} ** (max_n * max_n);
    for (0..n) |i| a[i] = values[2 + i];
    const aa_start = 2 + n;
    const bb_start = aa_start + n * n;
    for (0..n * n) |i| {
        aa[i] = values[aa_start + i];
        bb[i] = values[bb_start + i];
    }

    for (0..passes) |_| {
        for (1..n) |i| {
            for (0..n) |j| {
                const cell = j * n + i;
                a[i] = aa[cell] - a[i - 1];
                aa[cell] = a[i] + bb[cell];
            }
        }
    }
    var checksum: i64 = 0;
    for (0..n) |i| checksum += a[i];
    for (0..n * n) |i| checksum += aa[i];
    return checksum;
}
