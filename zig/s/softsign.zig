const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn softsign(x: f64) f64 {
    if (std.math.isNan(x) or x < -1.0e100 or x > 1.0e100) return INVALID_RESULT;
    return x / (1.0 + @abs(x));
}
