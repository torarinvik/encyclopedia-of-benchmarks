export fn neville(values: [*c]const i64, length: usize) f64 {
    const invalid: f64 = -1.0e300;
    if (values == null or length < 4 or length > 34) return invalid;
    const count = values[0];
    const target_i = values[1];
    if (count < 1 or count > 16 or length != @as(usize, @intCast(2 * count + 2)) or target_i < -1_000_000 or target_i > 1_000_000) return invalid;
    var x: [16]f64 = undefined;
    var p: [16]f64 = undefined;
    const n: usize = @intCast(count);
    for (0..n) |i| {
        const xi = values[2 + 2 * i];
        const yi = values[3 + 2 * i];
        if (xi < -1_000_000 or xi > 1_000_000 or yi < -1_000_000 or yi > 1_000_000) return invalid;
        for (0..i) |j| if (values[2 + 2 * j] == xi) return invalid;
        x[i] = @floatFromInt(xi);
        p[i] = @floatFromInt(yi);
    }
    const target: f64 = @floatFromInt(target_i);
    for (1..n) |k| {
        for (0..n - k) |i| p[i] = ((target - x[i + k]) * p[i] + (x[i] - target) * p[i + 1]) / (x[i] - x[i + k]);
    }
    return p[0];
}
