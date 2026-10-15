/// Solve the missing semiconductor carrier concentration.
const std = @import("std");

export fn carrier_concentration(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const electron_conc = values[0];
    const hole_conc = values[1];
    const intrinsic_conc = values[2];
    if (electron_conc < 0 or electron_conc > 1_000_000 or hole_conc < 0 or hole_conc > 1_000_000 or
        intrinsic_conc < 0 or intrinsic_conc > 1_000_000) return -1.0e300;
    const zero_count: i32 = @intFromBool(electron_conc == 0) + @intFromBool(hole_conc == 0) + @intFromBool(intrinsic_conc == 0);
    if (zero_count != 1) return -1.0e300;
    if (electron_conc == 0) return @as(f64, @floatFromInt(intrinsic_conc * intrinsic_conc)) / @as(f64, @floatFromInt(hole_conc));
    if (hole_conc == 0) return @as(f64, @floatFromInt(intrinsic_conc * intrinsic_conc)) / @as(f64, @floatFromInt(electron_conc));
    return std.math.pow(f64, @as(f64, @floatFromInt(electron_conc * hole_conc)), 0.5);
}
