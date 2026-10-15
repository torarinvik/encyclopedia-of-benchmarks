/// Squareplus activation for one element of the source vector.
const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn squareplus(x: f64, beta: f64) f64 {
    if (!std.math.isFinite(x) or !std.math.isFinite(beta) or x < -10000.0 or x > 10000.0 or beta < 0.25 or beta > 10000.0)
        return INVALID_RESULT;
    return (x + @sqrt(x * x + beta)) / 2.0;
}
