const std = @import("std");

export fn cos(x_value: f64) f64 {
    if (!(x_value >= -1000000.0 and x_value <= 1000000.0)) return -1.0;
    const tp = 1.0 / (2.0 * 3.141592653589793);
    var x = x_value * tp;
    x -= 0.25 + @floor(x + 0.25);
    x *= 16.0 * (@abs(x) - 0.5);
    x += 0.225 * x * (@abs(x) - 1.0);
    return x;
}
