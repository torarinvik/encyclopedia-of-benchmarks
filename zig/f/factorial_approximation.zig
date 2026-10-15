const std = @import("std");

export fn factorial_approximation(x: f64) f64 {
    if (!(x >= 0.0 and x <= 170.0)) return -1.0;
    return @sqrt(3.141592653589793) * std.math.pow(f64, x / 2.718281828459045, x)
        * std.math.pow(f64, 8.0 * std.math.pow(f64, x, 3.0) + 4.0 * std.math.pow(f64, x, 2.0) + x + 1.0 / 30.0, 1.0 / 6.0);
}
