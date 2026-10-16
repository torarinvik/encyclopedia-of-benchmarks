export fn optimal_file_merging(values: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 33) return -1;
    const count = values[0];
    if (count < 0 or count > 32 or length != @as(usize, @intCast(count)) + 1) return -1;
    var files: [32]i64 = [_]i64{0} ** 32;
    for (0..@as(usize, @intCast(count))) |i| {
        if (values[i + 1] < 0 or values[i + 1] > 1_000_000) return -1;
        files[i] = values[i + 1];
    }
    var n: usize = @intCast(count);
    var total: i64 = 0;
    while (n > 1) {
        var a: usize = 0;
        var b: usize = 1;
        if (files[b] < files[a]) { const t = a; a = b; b = t; }
        for (2..n) |i| {
            if (files[i] < files[a]) { b = a; a = i; }
            else if (files[i] < files[b]) { b = i; }
        }
        const merged = files[a] + files[b];
        total += merged;
        if (a > b) { const t = a; a = b; b = t; }
        files[a] = merged;
        files[b] = files[n - 1];
        n -= 1;
    }
    return total;
}
