const std = @import("std");

const MIN_VALUE: f64 = 1e-6;
const MAX_VALUE: f64 = 1e6;

export fn fast_inverse_sqrt_cpp(value: f64) f64 {
    if (!std.math.isFinite(value) or value < MIN_VALUE or value > MAX_VALUE) return -1.0;
    var y = value;
    const x2 = y * 0.5;
    const bits: i64 = @bitCast(y);
    const seed_bits: i64 = 0x5fe6eb50c7b537a9 - (bits >> 1);
    y = @bitCast(seed_bits);
    y = y * (1.5 - (x2 * y * y));
    y = y * (1.5 - (x2 * y * y));
    return y;
}
