const std = @import("std");

/// Pinned electric_power formula over the benchmark's bounded integer-valued domain.
pub export fn electric_power(voltage: f64, current: f64, power: f64) f64 {
    if (std.math.isNan(voltage) or std.math.isNan(current) or std.math.isNan(power)) return -1.0e300;
    if (voltage < -10000.0 or voltage > 10000.0 or current < -10000.0 or current > 10000.0) return -1.0e300;
    if (power < 0.0 or power > 100000000.0) return -1.0e300;
    if (voltage != @as(f64, @floatFromInt(@as(i64, @intFromFloat(voltage)))) or
        current != @as(f64, @floatFromInt(@as(i64, @intFromFloat(current)))) or
        power != @as(f64, @floatFromInt(@as(i64, @intFromFloat(power))))) return -1.0e300;
    const zeros: u8 = @intFromBool(voltage == 0.0) + @intFromBool(current == 0.0) + @intFromBool(power == 0.0);
    if (zeros != 1) return -1.0e300;
    if (voltage == 0.0) return power / current;
    if (current == 0.0) return power / voltage;
    const product = voltage * current;
    return if (product < 0.0) -product else product;
}
