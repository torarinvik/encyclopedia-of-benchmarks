const std = @import("std");

const PI: f64 = 3.141592653589793238462643383279502884;

fn roundTwoEven(value: f64) f64 {
    const scaled = value * 100.0;
    const lower = @floor(scaled);
    const fraction = scaled - lower;
    var rounded: i64 = @intFromFloat(lower);
    if (fraction > 0.5 or (fraction == 0.5 and @mod(rounded, 2) != 0)) rounded += 1;
    return @as(f64, @floatFromInt(rounded)) / 100.0;
}

export fn snells_law(n1: f64, n2: f64, incident_angle_degrees: f64) f64 {
    if (!std.math.isFinite(n1) or !std.math.isFinite(n2) or !std.math.isFinite(incident_angle_degrees) or
        n1 < 0.5 or n1 > 2.5 or n2 < 0.5 or n2 > 2.5 or incident_angle_degrees < -90.0 or incident_angle_degrees > 90.0)
        return -1.0e300;
    const incident_angle_radians = incident_angle_degrees * (PI / 180.0);
    const refraction_sine = (n1 / n2) * @sin(incident_angle_radians);
    const scale = @max(@abs(refraction_sine), 1.0);
    if (@abs(refraction_sine - 1.0) <= 1.0e-9 * scale) return 90.0;
    if (@abs(refraction_sine + 1.0) <= 1.0e-9 * scale) return -90.0;
    if (!(refraction_sine >= -1.0 and refraction_sine <= 1.0)) return -1.0e300;
    const refraction_angle_degrees = @asin(refraction_sine) * (180.0 / PI);
    return roundTwoEven(refraction_angle_degrees);
}
