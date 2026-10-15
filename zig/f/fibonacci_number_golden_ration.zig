const std = @import("std");

/// Binary64 Binet formula with Java Math.round semantics on the bounded domain.
export fn fibonacci_number_golden_ration(input: i64) i64 {
    if (input < 0 or input > 70) return -1;
    if (input <= 1) return input;

    const sqrt5 = @sqrt(@as(f64, 5.0));
    const phi = (1.0 + sqrt5) / 2.0;
    const psi = (1.0 - sqrt5) / 2.0;
    const exponent: f64 = @floatFromInt(input);
    const result = (std.math.pow(f64, phi, exponent) - std.math.pow(f64, psi, exponent)) / sqrt5;
    return @intFromFloat(@floor(result + 0.5));
}
