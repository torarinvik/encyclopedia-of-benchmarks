const INVALID_RESULT: f64 = -1.0e300;
const COORDINATE_LIMIT: f64 = 1_000_000.0;
const ANGLE_LIMIT_DEGREES: f64 = 36_000.0;
const DEGREES_PER_RADIAN: f64 = 57.2957795130823208768;
const RADIANS_PER_DEGREE: f64 = 0.0174532925199432957692;

#[no_mangle]
pub extern "C" fn coordinate_converter(first: f64, second: f64, component: f64) -> f64 {
    if component == 0.0 || component == 1.0 {
        if !first.is_finite() || !second.is_finite() ||
            first < -COORDINATE_LIMIT || first > COORDINATE_LIMIT ||
            second < -COORDINATE_LIMIT || second > COORDINATE_LIMIT { return INVALID_RESULT; }
        if component == 0.0 { return (first * first + second * second).sqrt(); }
        return second.atan2(first) * DEGREES_PER_RADIAN;
    }
    if component == 2.0 || component == 3.0 {
        if !first.is_finite() || !second.is_finite() || first < 0.0 ||
            first > COORDINATE_LIMIT || second < -ANGLE_LIMIT_DEGREES ||
            second > ANGLE_LIMIT_DEGREES { return INVALID_RESULT; }
        let radians = second * RADIANS_PER_DEGREE;
        return first * (if component == 2.0 { radians.cos() } else { radians.sin() });
    }
    INVALID_RESULT
}
