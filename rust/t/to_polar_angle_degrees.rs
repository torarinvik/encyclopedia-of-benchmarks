const INVALID_RESULT: f64 = -1.0e300;
const PI: f64 = 3.141592653589793238462643383279502884;

/// Match the pinned MATLAB to_polar angle formula in degrees.
#[no_mangle]
pub extern "C" fn to_polar_angle_degrees(x: f64, y: f64) -> f64 {
    if x.is_nan() || y.is_nan() || !(-1_000_000.0..=1_000_000.0).contains(&x) ||
        !(-1_000_000.0..=1_000_000.0).contains(&y) || (x == 0.0 && y == 0.0) {
        return INVALID_RESULT;
    }
    let theta = if x >= 0.0 { (y / x).atan() } else { (y / x).atan() + PI };
    theta * (180.0 / PI)
}
