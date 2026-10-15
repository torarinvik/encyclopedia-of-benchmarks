/// Degree-based sine approximation from the pinned Python Taylor-series source.
#[no_mangle]
pub extern "C" fn sin_degrees(angle_value: f64) -> f64 {
    if !(angle_value >= -1_000_000.0 && angle_value <= 1_000_000.0) {
        return -1.0;
    }

    let angle = angle_value - (angle_value / 360.0).floor() * 360.0;
    let radians = angle * (std::f64::consts::PI / 180.0);
    let mut result = radians;
    let mut sign = -1.0;
    let mut exponent = 3i32;
    for _ in 0..18 {
        let mut factorial = 1.0;
        for factor in 2..=exponent {
            factorial *= f64::from(factor);
        }
        result += sign * radians.powf(f64::from(exponent)) / factorial;
        sign = -sign;
        exponent += 2;
    }
    (result * 10_000_000_000.0).round() / 10_000_000_000.0
}
