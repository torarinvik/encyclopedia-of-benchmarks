/// Binary step over a bounded finite binary64 domain.
const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn binary_step(x: f64) f64 {
    if (!std.math.isFinite(x) or x < -1_000_000.0 or x > 1_000_000.0) return INVALID_RESULT;
    return if (x >= 0.0) 1.0 else 0.0;
}
