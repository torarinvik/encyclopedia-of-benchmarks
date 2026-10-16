const INVALID_RESULT = -1.0e300;
const DEGREE_FACTOR = 57.2957795130823208768;

fn roundTwoAway(value: f64) f64 {
    if (value == 0.0) return value;
    const scaled = value * 100.0;
    if (scaled >= 0.0) return @as(f64, @floatFromInt(@as(i64, @intFromFloat(scaled + 0.5)))) / 100.0;
    const units: i64 = @intFromFloat(scaled - 0.5);
    if (units == 0) return -0.0;
    return @as(f64, @floatFromInt(units)) / 100.0;
}

export fn rectangular_to_polar(real: f64, imag: f64, component: f64) f64 {
    if (std.math.isNan(real) or std.math.isNan(imag) or std.math.isNan(component) or
        @abs(real) > 1000000.0 or @abs(imag) > 1000000.0 or
        (component != 0.0 and component != 1.0)) return INVALID_RESULT;
    if (component == 0.0) return roundTwoAway(@sqrt(real * real + imag * imag));
    return roundTwoAway(@atan2(imag, real) * DEGREE_FACTOR);
}

const std = @import("std");
