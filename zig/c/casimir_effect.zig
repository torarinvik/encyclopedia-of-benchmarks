/// Solve one missing quantity in the ideal-plate Casimir force equation.
const std = @import("std");

export fn casimir_effect(values: [*]const i64, length: usize) f64 {
    const hbar = 1.054571817e-34;
    const speed_of_light = 3.0e8;
    const pi_value = 3.14159265358979323846;
    if (length != 3) return -1.0e300;
    const force_units = values[0];
    const area_units = values[1];
    const distance_units = values[2];
    if (force_units < 0 or force_units > 1_000_000 or area_units < 0 or area_units > 1_000_000 or
        distance_units < 0 or distance_units > 1_000_000) return -1.0e300;
    const zero_count: u8 = @intFromBool(force_units == 0) + @intFromBool(area_units == 0) + @intFromBool(distance_units == 0);
    if (zero_count != 1) return -1.0e300;
    const force = @as(f64, @floatFromInt(force_units)) * 1.0e-12;
    const area = @as(f64, @floatFromInt(area_units)) * 1.0e-6;
    const distance = @as(f64, @floatFromInt(distance_units)) * 1.0e-6;
    if (force_units == 0)
        return (hbar * speed_of_light * std.math.pow(f64, pi_value, 2.0) * area) /
            (240.0 * std.math.pow(f64, distance, 4.0));
    if (area_units == 0)
        return (240.0 * force * std.math.pow(f64, distance, 4.0)) /
            (hbar * speed_of_light * std.math.pow(f64, pi_value, 2.0));
    return std.math.pow(f64, (hbar * speed_of_light * std.math.pow(f64, pi_value, 2.0) * area) /
        (240.0 * force), 0.25);
}
