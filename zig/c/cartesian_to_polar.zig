/// Return radius for component 0 and the atan2 angle for component 1.
const std = @import("std");

pub export fn cartesian_to_polar(x: f64, y: f64, component: f64) f64 {
    if (std.math.isNan(x) or std.math.isNan(y) or (component != 0.0 and component != 1.0) or
        x < -1000000.0 or x > 1000000.0 or y < -1000000.0 or y > 1000000.0) return -1.0e300;
    if (component == 0.0) return @sqrt(x * x + y * y);
    if (x == 0.0 and y == 0.0) return 0.0;
    return @atan2(y, x);
}
