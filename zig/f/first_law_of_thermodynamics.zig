const std = @import("std");

/// Numeric first-law operations over a bounded integer-valued domain.
pub export fn first_law_of_thermodynamics(operation: f64, a: f64, b: f64) f64 {
    if (!std.math.isFinite(operation) or !std.math.isFinite(a) or !std.math.isFinite(b)) return -1e300;
    if (operation < 0.0 or operation > 2.0 or operation != @as(f64, @floatFromInt(@as(i64, @intFromFloat(operation))))) return -1e300;
    if (a < -1000000.0 or a > 1000000.0 or b < -1000000.0 or b > 1000000.0) return -1e300;
    if (a != @as(f64, @floatFromInt(@as(i64, @intFromFloat(a)))) or
        b != @as(f64, @floatFromInt(@as(i64, @intFromFloat(b))))) return -1e300;
    if (operation == 0.0) return a - b;
    if (operation == 1.0) return a + b;
    return a - b;
}
