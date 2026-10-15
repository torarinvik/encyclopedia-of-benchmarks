/// Hyperbolic tangent using the normalized logistic identity.
const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn tanh(x: f64) f64 {
    if (!std.math.isFinite(x) or x < -10.0 or x > 10.0) return INVALID_RESULT;
    return (2.0 / (1.0 + @exp(-2.0 * x))) - 1.0;
}
