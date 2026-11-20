const std = @import("std");

export fn modified_newton_multiple_root(initial_x: f64, iteration_count: f64) f64 {
    if (!std.math.isFinite(initial_x) or !std.math.isFinite(iteration_count) or
        initial_x < 1.0 or initial_x > 2.0 or iteration_count < 0.0 or
        iteration_count > 8.0 or @floor(iteration_count) != iteration_count)
    {
        return -1.0;
    }

    var x = initial_x;
    const count: usize = @intFromFloat(iteration_count);
    for (0..count) |_| {
        if (x == 1.0) break;
        const offset = x - 1.0;
        const value = offset * offset * (x + 2.0);
        const derivative = 3.0 * offset * (x + 1.0);
        if (derivative == 0.0 or !std.math.isFinite(derivative)) return -1.0;
        x -= 2.0 * (value / derivative);
        if (!std.math.isFinite(x) or x < 1.0 or x > 2.0) return -1.0;
    }
    return x;
}
