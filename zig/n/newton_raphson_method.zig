const INVALID_RESULT: f64 = -1.0e300;
const std = @import("std");

fn equation(x: f64) f64 { return std.math.pow(f64, x, 3.0) - (4.0 * x) - 9.0; }
fn derivative(x: f64) f64 { return 3.0 * std.math.pow(f64, x, 2.0) - 4.0; }

export fn newton_raphson_method(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const initial_milli = values[0];
    const iteration_limit = values[1];
    if (initial_milli < 2000 or initial_milli > 4000 or iteration_limit < 1 or iteration_limit > 32)
        return INVALID_RESULT;
    var c = @as(f64, @floatFromInt(initial_milli)) / 1000.0;
    var z = c;
    for (0..@intCast(iteration_limit)) |_| {
        const m = equation(c);
        const n = derivative(c);
        z = c - (m / n);
        c = z;
        if (@abs(m) < 1e-10) break;
    }
    return z;
}
