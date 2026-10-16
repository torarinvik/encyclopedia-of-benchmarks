const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;
const COORDINATE_LIMIT: f64 = 1_000_000.0;
const ANGLE_LIMIT_DEGREES: f64 = 36_000.0;
const DEGREES_PER_RADIAN: f64 = 57.2957795130823208768;
const RADIANS_PER_DEGREE: f64 = 0.0174532925199432957692;

export fn coordinate_converter(first: f64, second: f64, component: f64) f64 {
    if (component == 0.0 or component == 1.0) {
        if (!std.math.isFinite(first) or !std.math.isFinite(second) or
            first < -COORDINATE_LIMIT or first > COORDINATE_LIMIT or
            second < -COORDINATE_LIMIT or second > COORDINATE_LIMIT) return INVALID_RESULT;
        if (component == 0.0) return @sqrt(first * first + second * second);
        return @atan2(second, first) * DEGREES_PER_RADIAN;
    }
    if (component == 2.0 or component == 3.0) {
        if (!std.math.isFinite(first) or !std.math.isFinite(second) or first < 0.0 or
            first > COORDINATE_LIMIT or second < -ANGLE_LIMIT_DEGREES or
            second > ANGLE_LIMIT_DEGREES) return INVALID_RESULT;
        const radians = second * RADIANS_PER_DEGREE;
        return first * (if (component == 2.0) @cos(radians) else @sin(radians));
    }
    return INVALID_RESULT;
}
