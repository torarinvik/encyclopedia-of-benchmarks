const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;
const E_VALUE: f64 = 2.71828182845904523536028747135266250;

export fn gaussian_error_linear_unit_tanh(x: f64) f64 {
    if (!std.math.isFinite(x) or x < -100.0 or x > 100.0) return INVALID_RESULT;
    const scale = std.math.pow(f64, 2.0 / PI_VALUE, 0.5);
    const z = scale * (x + 0.044715 * std.math.pow(f64, x, 3.0));
    const tanh_value = 2.0 / (1.0 + std.math.pow(f64, E_VALUE, -2.0 * z)) - 1.0;
    return x * 0.5 * (1.0 + tanh_value);
}
