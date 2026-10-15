/// Bragg diffraction angle, rounded to one decimal degree.
const PI: f64 = 3.141592653589793238462643383279502884;

fn roundOneEven(value: f64) f64 {
    const scaled = value * 10.0;
    const lower = @floor(scaled);
    const fraction = scaled - lower;
    var rounded: i64 = @intFromFloat(lower);
    if (fraction > 0.5 or (fraction == 0.5 and @mod(rounded, 2) != 0)) rounded += 1;
    return @as(f64, @floatFromInt(rounded)) / 10.0;
}

export fn bragg_angle(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const distance = values[0];
    const order = values[1];
    const wavelength = values[2];
    if (distance < 1 or distance > 1000000 or order < -1000 or order > 1000 or wavelength < 0 or wavelength > 1000000)
        return -1.0e300;
    const sine = (@as(f64, @floatFromInt(order)) * @as(f64, @floatFromInt(wavelength))) / (2.0 * @as(f64, @floatFromInt(distance)));
    if (sine < -1.0 or sine > 1.0) return -1.0e300;
    const degrees = @asin(sine) * (180.0 / PI);
    return roundOneEven(degrees);
}
