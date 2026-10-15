const std = @import("std");

/// Ohm's law over a bounded integer-valued input domain.
pub export fn ohms_law(voltage: f64, current: f64, resistance: f64) f64 {
    if (!std.math.isFinite(voltage) or !std.math.isFinite(current) or !std.math.isFinite(resistance)) return -1e300;
    if (voltage < -1000.0 or voltage > 1000.0 or current < -1000.0 or current > 1000.0 or resistance < 0.0 or resistance > 1000.0) return -1e300;
    if (voltage != @as(f64, @floatFromInt(@as(i64, @intFromFloat(voltage)))) or
        current != @as(f64, @floatFromInt(@as(i64, @intFromFloat(current)))) or
        resistance != @as(f64, @floatFromInt(@as(i64, @intFromFloat(resistance))))) return -1e300;
    const zeros: u8 = @intFromBool(voltage == 0.0) + @intFromBool(current == 0.0) + @intFromBool(resistance == 0.0);
    if (zeros != 1) return -1e300;
    if (voltage == 0.0) return current * resistance;
    if (current == 0.0) return voltage / resistance;
    return voltage / current;
}
