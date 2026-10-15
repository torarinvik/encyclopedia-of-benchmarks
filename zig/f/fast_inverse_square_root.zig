const std = @import("std");

const MIN_VALUE: f64 = 1e-6;
const MAX_VALUE: f64 = 1e6;

/// Match PHP's float32 pack/unpack through binary32 bit reinterpretation.
export fn fast_inverse_square_root(value: f64) f64 {
    if (!std.math.isFinite(value) or value < MIN_VALUE or value > MAX_VALUE) return -1.0;
    const seed_input: f32 = @floatCast(value);
    const bits: i32 = @bitCast(seed_input);
    const seed_bits: i32 = 0x5f3759df - (bits >> 1);
    const seed: f32 = @bitCast(seed_bits);
    const y: f64 = @floatCast(seed);
    return y * (1.5 - 0.5 * value * y * y);
}
