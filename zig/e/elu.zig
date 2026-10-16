const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;
const ALPHA_MAX: f64 = 1_000_000.0;

export fn elu(x: f64, alpha: f64) f64 {
    if (!std.math.isFinite(x) or !std.math.isFinite(alpha) or x < -100.0 or x > 100.0
        or alpha < -ALPHA_MAX or alpha > ALPHA_MAX) return INVALID_RESULT;
    return if (x < 0.0) alpha * (@exp(x) - 1.0) else x;
}
