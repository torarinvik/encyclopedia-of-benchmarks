const INVALID: f64 = -1.0e300;

export fn gradient_descent(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 5 or length > 68) return INVALID;
    const v = input.?[0..length];
    const d = v[0];
    const selected = v[1];
    const rate = v[2];
    const iterations = v[3];
    if (d < 1 or d > 64 or selected < 0 or selected >= d or length != 4 + @as(usize, @intCast(d)) or rate < 1 or rate > 500000 or iterations < 0 or iterations > 10000) return INVALID;
    const dim: usize = @intCast(d);
    const pick: usize = @intCast(selected);
    var x: [64]f64 = @splat(0);
    for (0..dim) |i| {
        if (v[4 + i] < -10 or v[4 + i] > 10) return INVALID;
        x[i] = @floatFromInt(v[4 + i]);
    }
    const alpha = @as(f64, @floatFromInt(rate)) / 1_000_000.0;
    for (0..@intCast(iterations)) |_| {
        var gradient: [64]f64 = @splat(0);
        for (0..dim) |i| gradient[i] = 2.0 * x[i];
        for (0..dim) |i| x[i] -= alpha * gradient[i];
    }
    return x[pick];
}
