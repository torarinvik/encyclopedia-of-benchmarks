const std = @import("std");

export fn sin_degrees(angle_value: f64) f64 {
    if (!(angle_value >= -1_000_000.0 and angle_value <= 1_000_000.0)) return -1.0;

    const angle = angle_value - @floor(angle_value / 360.0) * 360.0;
    const radians = angle * (3.141592653589793 / 180.0);
    var result = radians;
    var sign: f64 = -1.0;
    var exponent: u32 = 3;
    for (0..18) |_| {
        var factorial: f64 = 1.0;
        var factor: u32 = 2;
        while (factor <= exponent) : (factor += 1) {
            factorial *= @floatFromInt(factor);
        }
        result += sign * std.math.pow(f64, radians, @floatFromInt(exponent)) / factorial;
        sign = -sign;
        exponent += 2;
    }
    return @round(result * 10_000_000_000.0) / 10_000_000_000.0;
}
