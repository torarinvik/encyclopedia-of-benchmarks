/// Leaky ReLU for one vector element and a caller-supplied slope.
const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT: f64 = 1_000_000.0;

export fn leaky_relu(x: f64, alpha: f64) f64 {
    if (!std.math.isFinite(x) or !std.math.isFinite(alpha) or x < -MAX_INPUT or x > MAX_INPUT or alpha < -MAX_INPUT or alpha > MAX_INPUT)
        return INVALID_RESULT;
    return if (x < 0.0) x * alpha else x;
}
