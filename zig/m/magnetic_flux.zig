/// Magnetic flux rounded to one decimal place.
const std = @import("std");

export fn magnetic_flux(values: [*]const i64, length: usize) f64 {
    const pi_value = 3.14159265358979323846;
    if (length != 3) return -1.0e300;
    const magnetic_field = values[0];
    const area = values[1];
    const angle = values[2];
    if (magnetic_field < 0 or magnetic_field > 10_000 or area < 0 or area > 10_000 or
        !(angle == 0 or angle == 60 or angle == 90 or angle == 120 or angle == 180)) return -1.0e300;
    const radians = @as(f64, @floatFromInt(angle)) * (pi_value / 180.0);
    const flux = @as(f64, @floatFromInt(magnetic_field)) * @as(f64, @floatFromInt(area)) * @cos(radians);
    return @round(flux * 10.0) / 10.0;
}
