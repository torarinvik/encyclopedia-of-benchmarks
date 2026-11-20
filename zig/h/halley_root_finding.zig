const std = @import("std");

export fn halley_root_finding(initial_x: f64, iteration_count: f64) f64 {
    if (!std.math.isFinite(initial_x) or !std.math.isFinite(iteration_count) or
        initial_x < 0.5 or initial_x > 2.0 or iteration_count < 0.0 or
        iteration_count > 8.0 or @floor(iteration_count) != iteration_count)
    {
        return -1.0;
    }

    var x = initial_x;
    const count: usize = @intFromFloat(iteration_count);
    for (0..count) |_| {
        const value = x * x * x - 2.0;
        const first = 3.0 * x * x;
        const second = 6.0 * x;
        const denominator = 2.0 * first * first - value * second;
        if (denominator == 0.0 or !std.math.isFinite(denominator)) return -1.0;
        x -= (2.0 * value * first) / denominator;
        if (!std.math.isFinite(x)) return -1.0;
    }
    return x;
}
