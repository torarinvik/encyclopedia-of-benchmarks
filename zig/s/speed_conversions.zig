/// Convert a bounded speed between the four units in the pinned source.
fn roundThreeEven(value: f64) f64 {
    const lower = @floor(value * 1000.0);
    const midpoint = lower + 0.5;
    const exactSide = @mulAdd(f64, value, 1000.0, -midpoint);
    var rounded: i64 = @intFromFloat(lower);
    if (exactSide > 0.0 or (exactSide == 0.0 and @mod(rounded, 2) != 0)) rounded += 1;
    return @as(f64, @floatFromInt(rounded)) / 1000.0;
}

export fn speed_conversions(speed: f64, route: f64) f64 {
    if (!(speed >= 0.0 and speed <= 1_000_000.0) or !(route >= 0.0 and route <= 15.0) or @floor(route) != route) return -1.0;
    const factors = [_]f64{ 1.0, 3.6, 1.609344, 1.852 };
    const inverse_factors = [_]f64{ 1.0, 0.277777778, 0.621371192, 0.539956803 };
    const encoded: usize = @intFromFloat(route);
    return roundThreeEven(speed * factors[encoded / 4] * inverse_factors[encoded % 4]);
}
