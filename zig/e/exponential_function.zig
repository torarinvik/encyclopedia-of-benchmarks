const std = @import("std");

export fn exponential_function(power: f64, term_count: f64) f64 {
    if (!(power >= -10.0 and power <= 10.0 and term_count >= 0.0 and term_count <= 32.0)) return -1.0e300;
    const n: i32 = @intFromFloat(term_count);
    if (@as(f64, @floatFromInt(n)) != term_count) return -1.0e300;
    if (n == 0) return 1.0;

    var output: f64 = 0.0;
    var factorial: f64 = 1.0;
    for (0..@intCast(n)) |i| {
        const exponent: f64 = @floatFromInt(i);
        output += std.math.pow(f64, power, exponent) / factorial;
        factorial *= @as(f64, @floatFromInt(i + 1));
    }
    return output;
}
