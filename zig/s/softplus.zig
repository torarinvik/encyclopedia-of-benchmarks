const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn softplus(x: f64) f64 {
    if (std.math.isNan(x) or x < -100.0 or x > 100.0) return INVALID_RESULT;
    return @log(1.0 + @exp(x));
}
