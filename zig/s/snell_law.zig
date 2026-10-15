const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;
const HALF_PI: f64 = 1.5707963267948966;

export fn snell_law(n1: f64, n2: f64, theta1: f64) f64 {
    if (!std.math.isFinite(n1) or !std.math.isFinite(n2) or !std.math.isFinite(theta1) or
        n1 < 0.5 or n1 > 2.5 or n2 < 0.5 or n2 > 2.5 or theta1 < -HALF_PI or theta1 > HALF_PI)
    {
        return INVALID_RESULT;
    }
    const ratio = n1 / n2;
    const sin_theta2 = ratio * @sin(theta1);
    if (@abs(sin_theta2) > 1.0) return INVALID_RESULT;
    return @asin(sin_theta2);
}
