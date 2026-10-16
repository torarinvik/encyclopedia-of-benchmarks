package coordinate_converter

import "core:math"

INVALID_RESULT :: -1.0e300
COORDINATE_LIMIT :: 1_000_000.0
ANGLE_LIMIT_DEGREES :: 36_000.0
DEGREES_PER_RADIAN :: 57.2957795130823208768
RADIANS_PER_DEGREE :: 0.0174532925199432957692

@(export)
coordinate_converter :: proc "c" (first, second, component: f64) -> f64 {
    if component == 0.0 || component == 1.0 {
        if first != first || second != second ||
            first < -COORDINATE_LIMIT || first > COORDINATE_LIMIT ||
            second < -COORDINATE_LIMIT || second > COORDINATE_LIMIT do return INVALID_RESULT
        if component == 0.0 do return math.sqrt_f64(first * first + second * second)
        return math.atan2(second, first) * DEGREES_PER_RADIAN
    }
    if component == 2.0 || component == 3.0 {
        if first != first || second != second || first < 0.0 ||
            first > COORDINATE_LIMIT || second < -ANGLE_LIMIT_DEGREES ||
            second > ANGLE_LIMIT_DEGREES do return INVALID_RESULT
        radians := second * RADIANS_PER_DEGREE
        if component == 2.0 do return first * math.cos(radians)
        return first * math.sin(radians)
    }
    return INVALID_RESULT
}
