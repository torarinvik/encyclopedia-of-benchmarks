const INVALID_RESULT: f64 = -1.0e300;
const PI: f64 = 3.141592653589793238462643383279502884;

fn round_two_even(value: f64) -> f64 {
    let scaled = value * 100.0;
    let lower = scaled.floor();
    let fraction = scaled - lower;
    let mut rounded = lower as i64;
    if fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0) {
        rounded += 1;
    }
    rounded as f64 / 100.0
}

#[no_mangle]
pub extern "C" fn snells_law(n1: f64, n2: f64, incident_angle_degrees: f64) -> f64 {
    if !n1.is_finite() || !n2.is_finite() || !incident_angle_degrees.is_finite() ||
        !(0.5..=2.5).contains(&n1) || !(0.5..=2.5).contains(&n2) ||
        !(-90.0..=90.0).contains(&incident_angle_degrees)
    {
        return INVALID_RESULT;
    }
    let incident_angle_radians = incident_angle_degrees * (PI / 180.0);
    let refraction_sine = (n1 / n2) * incident_angle_radians.sin();
    let scale = refraction_sine.abs().max(1.0);
    if (refraction_sine - 1.0).abs() <= 1.0e-9 * scale {
        return 90.0;
    }
    if (refraction_sine + 1.0).abs() <= 1.0e-9 * scale {
        return -90.0;
    }
    if !(-1.0..=1.0).contains(&refraction_sine) {
        return INVALID_RESULT;
    }
    let refraction_angle_degrees = refraction_sine.asin() * (180.0 / PI);
    round_two_even(refraction_angle_degrees)
}
