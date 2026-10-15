/// Newton-Raphson square root under the pinned integer input contract.
const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT: f64 = 2147483647.0;

export fn square_root_with_newton_raphson_method(input: f64) f64 {
    if (!std.math.isFinite(input) or input < 1.0 or input > MAX_INPUT) return INVALID_RESULT;
    if (@as(f64, @floatFromInt(@as(i64, @intFromFloat(input)))) != input) return INVALID_RESULT;
    var guess = input;
    var root = 0.5 * (guess + input / guess);
    while (@abs(root - guess) > 1e-7) {
        guess = root;
        root = 0.5 * (guess + input / guess);
    }
    return root;
}
