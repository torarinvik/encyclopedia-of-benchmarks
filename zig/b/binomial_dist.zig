const std = @import("std");

/// Probability of exactly x successes in n Bernoulli trials.
export fn binomial_dist(n: f64, p: f64, x: f64) f64 {
    const n_integer: i32 = @intFromFloat(n);
    const x_integer: i32 = @intFromFloat(x);
    var numerator = n;
    var denominator = x;
    var i = n_integer - 1;
    while (i >= n_integer - x_integer + 1) : (i -= 1) {
        numerator *= @as(f64, @floatFromInt(i));
    }
    i = 1;
    while (i < x_integer) : (i += 1) {
        denominator *= @as(f64, @floatFromInt(i));
    }
    return (numerator / denominator) * std.math.pow(f64, p, x)
        * std.math.pow(f64, 1.0 - p, n - x);
}
