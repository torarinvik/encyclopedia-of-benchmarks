const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn swish(x: f64) f64 {
    if (!std.math.isFinite(x) or x < -100.0 or x > 100.0) return INVALID_RESULT;
    const scaled = 1.0 * x;
    return x * (1.0 / (1.0 + @exp(-scaled)));
}
