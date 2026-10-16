const std = @import("std");
const PI: f64 = 3.141592653589793238462643383279502884;
const INVALID_RESULT: f64 = -1.0e300;

pub export fn to_polar_angle_degrees(x: f64, y: f64) f64 {
    if (std.math.isNan(x) or std.math.isNan(y) or x < -1000000.0 or x > 1000000.0 or
        y < -1000000.0 or y > 1000000.0 or (x == 0.0 and y == 0.0)) return INVALID_RESULT;
    const theta = if (x >= 0.0) @atan(y / x) else @atan(y / x) + PI;
    return theta * (180.0 / PI);
}
