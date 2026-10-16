/// Convert a bounded speed between the five units in the pinned source.
fn roundTwoPhp(value: f64) f64 {
    return @floor(value * 100.0 + 0.5) / 100.0;
}

export fn speed_conversion(speed: f64, route: f64) f64 {
    if (!(speed >= 0.0 and speed <= 1_000_000.0) or !(route >= 0.0 and route <= 24.0) or @floor(route) != route) return -1.0;
    const factors = [_]f64{ 1.609344, 1.0, 3.6, 1.097, 1.852 };
    const inverse_factors = [_]f64{ 0.6213712, 1.0, 0.277778, 0.911344, 0.539957 };
    const encoded: usize = @intFromFloat(route);
    return roundTwoPhp(speed * factors[encoded / 5] * inverse_factors[encoded % 5]);
}
