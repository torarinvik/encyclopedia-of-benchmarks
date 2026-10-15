/// Small-amplitude pendulum period: 2 * pi * sqrt(length / g).
const std = @import("std");
const PI: f64 = 3.141592653589793238462643383279502884;

export fn period_of_pendulum(values: [*]const i64, length: usize) f64 {
    if (length != 1) return -1.0e300;
    const pendulum_length = values[0];
    if (pendulum_length < 0 or pendulum_length > 1000) return -1.0e300;
    const root = std.math.pow(f64, @as(f64, @floatFromInt(pendulum_length)) / 9.80665, 0.5);
    return (2.0 * PI) * root;
}
