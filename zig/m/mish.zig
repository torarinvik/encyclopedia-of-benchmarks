/// Mish activation for one element of the source vector.
const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn mish(x: f64) f64 {
    if (!std.math.isFinite(x) or x < -20.0 or x > 20.0) return INVALID_RESULT;
    const softplus = @log(1.0 + @exp(x));
    return x * std.math.tanh(softplus);
}
