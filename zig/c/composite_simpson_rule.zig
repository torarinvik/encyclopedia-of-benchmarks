const std = @import("std");

const INVALID_RESULT: f64 = -1.0;
const MAX_INTERVALS: i32 = 128;

fn sample(function_id: i32, x: f64) f64 {
    return switch (function_id) {
        0 => @sqrt(x) + @log(x),
        1 => @exp(-x) * (4.0 - std.math.pow(f64, x, 2.0)),
        2 => @sqrt(2.0 * std.math.pow(f64, x, 3.0) + 3.0),
        else => x + @log(2.0 * x + 1.0),
    };
}

export fn composite_simpson_rule(intervals_input: f64, function_id_input: f64) f64 {
    if (!std.math.isFinite(intervals_input) or !std.math.isFinite(function_id_input) or
        intervals_input < 2.0 or intervals_input > @as(f64, @floatFromInt(MAX_INTERVALS)) or
        function_id_input < 0.0 or function_id_input > 3.0 or
        @trunc(intervals_input) != intervals_input or @trunc(function_id_input) != function_id_input) return INVALID_RESULT;
    const intervals: i32 = @intFromFloat(intervals_input);
    if (intervals % 2 != 0) return INVALID_RESULT;
    const function_id: i32 = @intFromFloat(function_id_input);
    const h = 2.0 / @as(f64, @floatFromInt(intervals));
    var x: f64 = 1.0;
    var sum: f64 = 0.0;
    var i: i32 = 0;
    while (i <= intervals) : (i += 1) {
        const y = sample(function_id, x);
        const weight: f64 = if (i == 0 or i == intervals) 1.0 else if (i % 2 == 1) 4.0 else 2.0;
        sum += weight * y;
        x += h;
    }
    return sum * (h / 3.0);
}
