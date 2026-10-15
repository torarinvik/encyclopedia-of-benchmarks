/// Rectified linear unit over a bounded integer-valued binary64 domain.
const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT: f64 = 16_777_216.0;

export fn relu(x: f64) f64 {
    if (!std.math.isFinite(x) or x < -MAX_INPUT or x > MAX_INPUT or @as(f64, @floatFromInt(@as(i64, @intFromFloat(x)))) != x) return INVALID_RESULT;
    return if (x > 0.0) x else 0.0;
}
