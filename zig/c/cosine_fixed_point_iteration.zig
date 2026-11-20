const std = @import("std");

export fn cosine_fixed_point_iteration(initial_input: f64, source_n: f64) f64 {
    if (!std.math.isFinite(initial_input) or !std.math.isFinite(source_n) or
        initial_input < 0.0 or initial_input > 2.0 or source_n < 0.0 or source_n > 64.0 or
        @floor(source_n) != source_n)
    {
        return -1.0;
    }

    var value = initial_input;
    const updates: usize = @as(usize, @intFromFloat(source_n)) + 1;
    for (0..updates) |_| {
        value = 0.5 * (@cos(value) + 2.0);
    }
    return value;
}
