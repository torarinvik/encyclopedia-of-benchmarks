const std = @import("std");

/// Sherman rainfall intensity curve over bounded integer inputs.
export fn rainfall_intensity(values: [*]const i64, length: usize) f64 {
    if (length != 6) return -1.0e300;
    const k = values[0];
    const a = values[1];
    const b = values[2];
    const c = values[3];
    const period = values[4];
    const duration = values[5];
    if (k < 1 or k > 1000 or a < 1 or a > 3 or b < 1 or b > 100 or c < 1 or c > 3 or period < 1 or period > 100 or duration < 1 or duration > 1000)
        return -1.0e300;
    return (@as(f64, @floatFromInt(k)) * std.math.pow(f64, @as(f64, @floatFromInt(period)), @as(f64, @floatFromInt(a)))) /
        std.math.pow(f64, @as(f64, @floatFromInt(duration + b)), @as(f64, @floatFromInt(c)));
}
