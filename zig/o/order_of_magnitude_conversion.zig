const std = @import("std");

const MAX_VALUE: f64 = 1e100;

fn unitExponent(code: f64) i32 {
    if (code == 0.0) return 0;
    if (code == 1.0) return 3;
    if (code == 2.0) return 6;
    if (code == 3.0) return 9;
    if (code == 4.0) return 12;
    if (code == 5.0) return 15;
    if (code == 6.0) return 18;
    if (code == 7.0) return 21;
    if (code == 8.0) return 24;
    return -1;
}

/// Preserve the source formula and operation order: value * 10^(from - to).
export fn order_of_magnitude_conversion(value: f64, from_unit_code: f64, to_unit_code: f64) f64 {
    if (std.math.isNan(value) or value < -MAX_VALUE or value > MAX_VALUE) return -1.0;
    const from_exp = unitExponent(from_unit_code);
    const to_exp = unitExponent(to_unit_code);
    if (from_exp < 0 or to_exp < 0) return -1.0;
    return value * std.math.pow(f64, 10.0, @as(f64, @floatFromInt(from_exp - to_exp)));
}
