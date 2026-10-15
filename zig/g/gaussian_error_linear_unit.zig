const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn gaussian_error_linear_unit(x: f64) f64 {
    if (!std.math.isFinite(x) or x < -100.0 or x > 100.0) return INVALID_RESULT;
    return x * (1.0 / (1.0 + @exp(-1.702 * x)));
}
