/// Escape velocity with the source's three-decimal result rounding.
fn roundThreeEven(value: f64) f64 {
    const scaled = value * 1000.0;
    const lower = @floor(scaled);
    const midpoint = lower + 0.5;
    const exact_side = @mulAdd(f64, value, 1000.0, -midpoint);
    var rounded: i64 = @intFromFloat(lower);
    if (exact_side > 0.0 or (exact_side == 0.0 and @mod(rounded, 2) != 0)) rounded += 1;
    return @as(f64, @floatFromInt(rounded)) / 1000.0;
}

export fn escape_velocity(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const mass = values[0];
    const radius = values[1];
    if (mass < 0 or mass > 1000000000000000 or radius < 1 or radius > 1000000000) return -1.0e300;
    const velocity = @sqrt(2.0 * 6.67430e-11 * @as(f64, @floatFromInt(mass)) / @as(f64, @floatFromInt(radius)));
    return roundThreeEven(velocity);
}
