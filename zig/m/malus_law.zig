/// Malus's law: I0 * cos(radians(angle))^2.
const std = @import("std");
const PI: f64 = 3.141592653589793238462643383279502884;

export fn malus_law(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const initial_intensity = values[0];
    const angle = values[1];
    if (initial_intensity < 0 or initial_intensity > 1000 or angle < 0 or angle > 360)
        return -1.0e300;
    const radians = (@as(f64, @floatFromInt(angle)) * PI) / 180.0;
    const cosine = @cos(radians);
    return @as(f64, @floatFromInt(initial_intensity)) * (cosine * cosine);
}
