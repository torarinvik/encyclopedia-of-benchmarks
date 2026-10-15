const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn nth_root(radicand: f64, index: f64, tolerance: f64) f64 {
    if (!std.math.isFinite(radicand) or !std.math.isFinite(index) or !std.math.isFinite(tolerance) or
        radicand < 0.5 or radicand > 1000.0 or index < 3.0 or index > 8.0 or
        @floor(index) != index or tolerance < 1.0e-12 or tolerance > 1.0e-3)
    {
        return INVALID_RESULT;
    }
    var new_approximation = radicand;
    var old_approximation = new_approximation + tolerance + 0.1;
    while (tolerance <= @abs(old_approximation - new_approximation)) {
        old_approximation = new_approximation;
        const first_summand = (index - 1.0) / index * old_approximation;
        const second_summand = radicand / (index * std.math.pow(f64, old_approximation, index - 1.0));
        new_approximation = first_summand + second_summand;
    }
    return new_approximation;
}
