const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

export fn hubble_parameter(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 5) return INVALID_RESULT;
    const h0_x10, radiation_ppm, matter_ppm, dark_energy_ppm, redshift_milli = .{ values[0], values[1], values[2], values[3], values[4] };
    if (h0_x10 < -2000 or h0_x10 > 2000 or radiation_ppm < 0 or radiation_ppm > 1_000_000 or
        matter_ppm < 0 or matter_ppm > 1_000_000 or dark_energy_ppm < 0 or dark_energy_ppm > 1_000_000 or
        radiation_ppm + matter_ppm + dark_energy_ppm > 1_000_000 or redshift_milli < 0 or redshift_milli > 10_000) return INVALID_RESULT;
    const hubble_constant: f64 = @as(f64, @floatFromInt(h0_x10)) / 10.0;
    const radiation_density: f64 = @as(f64, @floatFromInt(radiation_ppm)) / 1_000_000.0;
    const matter_density: f64 = @as(f64, @floatFromInt(matter_ppm)) / 1_000_000.0;
    const dark_energy: f64 = @as(f64, @floatFromInt(dark_energy_ppm)) / 1_000_000.0;
    const redshift: f64 = @as(f64, @floatFromInt(redshift_milli)) / 1_000.0;
    const curvature = 1.0 - (matter_density + radiation_density + dark_energy);
    const z1 = redshift + 1.0;
    const e2 = radiation_density * std.math.pow(f64, z1, 4.0) + matter_density * std.math.pow(f64, z1, 3.0) + curvature * std.math.pow(f64, z1, 2.0) + dark_energy;
    return hubble_constant * std.math.pow(f64, e2, 1.0 / 2.0);
}
