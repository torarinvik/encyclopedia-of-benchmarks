export fn verlet(values: [*c]const f64, length: usize, output: [*c]f64, capacity: usize) i64 {
    if (values == null or length != 4) return -1;
    for (0..4) |i| if (values[i] != values[i]) return -1;
    if (values[0] < 2.0 or values[0] > 32.0 or @floor(values[0]) != values[0] or
        values[1] < -1.0 or values[1] > 1.0 or
        values[2] < -1.0 or values[2] > 1.0 or
        values[3] < 0.0 or values[3] > 4.0 or @floor(values[3]) != values[3]) return -1;

    const n: usize = @intFromFloat(values[0]);
    const code: usize = @intFromFloat(values[3]);
    const step_sizes = [_]f64{ 0.00390625, 0.0078125, 0.015625, 0.03125, 0.0625 };
    const dt = step_sizes[code];
    const dt_squared = dt * dt;
    if (output == null or capacity < 2 * n) return -2;

    output[0] = values[1];
    output[1] = values[1] + values[2] * dt + 0.5 * (-values[1]) * dt_squared;
    for (1..n - 1) |i| {
        output[i + 1] = 2.0 * output[i] - output[i - 1] + (-output[i]) * dt_squared;
    }
    for (0..n) |i| {
        output[n + i] = @as(f64, @floatFromInt(i)) * dt;
    }
    return @intCast(2 * n);
}
