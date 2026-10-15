const std = @import("std");

/// Shear stress, force, and area relation over a bounded integer-valued domain.
pub export fn shear_stress(stress: f64, tangential_force: f64, area: f64) f64 {
    if (!std.math.isFinite(stress) or !std.math.isFinite(tangential_force) or !std.math.isFinite(area)) return -1.0;
    if (stress < 0.0 or stress > 1000.0 or tangential_force < 0.0 or tangential_force > 1000.0 or area < 0.0 or area > 1000.0) return -1.0;
    if (stress != @as(f64, @floatFromInt(@as(i64, @intFromFloat(stress)))) or
        tangential_force != @as(f64, @floatFromInt(@as(i64, @intFromFloat(tangential_force)))) or
        area != @as(f64, @floatFromInt(@as(i64, @intFromFloat(area))))) return -1.0;
    const zeros: u8 = @intFromBool(stress == 0.0) + @intFromBool(tangential_force == 0.0) + @intFromBool(area == 0.0);
    if (zeros != 1) return -1.0;
    if (stress == 0.0) return tangential_force / area;
    if (tangential_force == 0.0) return stress * area;
    return tangential_force / stress;
}
