/// Solve Newton's law of gravitation for one missing parameter.
const GRAVITATIONAL_CONSTANT: f64 = 6.6743e-11;

export fn newtons_law_of_gravitation(values: [*]const i64, length: usize) f64 {
    if (length != 4) return -1.0e300;
    const target = values[0];
    const a = values[1];
    const b = values[2];
    const c = values[3];
    if (target < 0 or target > 3 or a < 1 or a > 1000 or b < 1 or b > 1000 or c < 1 or c > 1000)
        return -1.0e300;
    switch (target) {
        0 => return GRAVITATIONAL_CONSTANT * (@as(f64, @floatFromInt(a)) * @as(f64, @floatFromInt(b))) / (@as(f64, @floatFromInt(c)) * @as(f64, @floatFromInt(c))),
        1 => return @as(f64, @floatFromInt(a)) * (@as(f64, @floatFromInt(c)) * @as(f64, @floatFromInt(c))) / (GRAVITATIONAL_CONSTANT * @as(f64, @floatFromInt(b))),
        2 => return @as(f64, @floatFromInt(a)) * (@as(f64, @floatFromInt(c)) * @as(f64, @floatFromInt(c))) / (GRAVITATIONAL_CONSTANT * @as(f64, @floatFromInt(b))),
        else => return @sqrt((GRAVITATIONAL_CONSTANT * (@as(f64, @floatFromInt(b)) * @as(f64, @floatFromInt(c)))) / @as(f64, @floatFromInt(a))),
    }
}
