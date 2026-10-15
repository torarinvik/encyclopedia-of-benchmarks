const std = @import("std");

const MIN_VALUE: f64 = 1e-6;
const MAX_VALUE: f64 = 1e6;

fn newtonStep(x2: f32, y: f32) f32 {
    const product1: f32 = x2 * y;
    const product2: f32 = product1 * y;
    const correction: f32 = 1.5 - product2;
    return y * correction;
}

/// Match Go's two binary32 Newton corrections after the magic-number seed.
export fn fast_inverse_sqrt_go(value: f64) f64 {
    if (!std.math.isFinite(value) or value < MIN_VALUE or value > MAX_VALUE) return -1.0;
    const number: f32 = @floatCast(value);
    const x2: f32 = number * 0.5;
    const bits: u32 = @bitCast(number);
    const seed_bits = 0x5f3759df - (bits >> 1);
    var y: f32 = @bitCast(seed_bits);
    y = newtonStep(x2, y);
    y = newtonStep(x2, y);
    return @floatCast(y);
}
