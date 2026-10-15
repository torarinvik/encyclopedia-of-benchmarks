/// Speed of sound in a fluid: (bulk modulus / density) ** 0.5.
const std = @import("std");

export fn speed_of_sound(values: [*]const i64, length: usize) f64 {
    if (length != 2) return -1.0e300;
    const density = values[0];
    const bulk_modulus = values[1];
    if (density < 1 or density > 1000 or bulk_modulus < 1 or bulk_modulus > 1_000_000_000)
        return -1.0e300;
    return std.math.pow(f64, @as(f64, @floatFromInt(bulk_modulus)) / @as(f64, @floatFromInt(density)), 0.5);
}
