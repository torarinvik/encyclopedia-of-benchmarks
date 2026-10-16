const INVALID_RESULT: f64 = -1.0e300;
const std = @import("std");

fn integrand(function_id: i64, x: f64) f64 {
    return switch (function_id) {
        0 => @sqrt(x) + @log(x),
        1 => @exp(-x) * (4.0 - std.math.pow(f64, x, 2.0)),
        2 => @sqrt(2.0 * std.math.pow(f64, x, 3.0) + 3.0),
        3 => x + @log(2.0 * x + 1.0),
        else => INVALID_RESULT,
    };
}

export fn midpoint_integral_method(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 4) return INVALID_RESULT;
    const function_id = values[0];
    const intervals = values[1];
    const a_milli = values[2];
    const b_milli = values[3];
    if (function_id < 0 or function_id > 3 or intervals < 2 or intervals > 64 or @rem(intervals, 2) != 0 or
        a_milli < 0 or a_milli >= b_milli or b_milli > 10000) return INVALID_RESULT;
    const a = @as(f64, @floatFromInt(a_milli)) / 1000.0;
    const b = @as(f64, @floatFromInt(b_milli)) / 1000.0;
    const h = (b - a) / @as(f64, @floatFromInt(intervals));
    var xi = a;
    var total: f64 = 0.0;
    for (0..@intCast(intervals)) |_| {
        total += integrand(function_id, xi + h / 2.0);
        xi += h;
    }
    return total * h;
}
