const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn sigmoid(x: f64) f64 {
    if (std.math.isNan(x) or x < -20.0 or x > 20.0) return INVALID_RESULT;
    return 1.0 / (1.0 + @exp(-x));
}
