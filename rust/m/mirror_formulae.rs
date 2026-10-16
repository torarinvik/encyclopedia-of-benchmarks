fn valid_distance(value: f64) -> bool {
    (value >= -1.0e6 && value <= -1.0e-6) || (value >= 1.0e-6 && value <= 1.0e6)
}

/// The source module exposes three mirror-equation rearrangements.
#[no_mangle]
pub extern "C" fn mirror_formulae(distance_a: f64, distance_b: f64, operation_code: f64) -> f64 {
    const INVALID: f64 = -1.0e300;
    if !valid_distance(distance_a) || !valid_distance(distance_b)
        || !(operation_code == 0.0 || operation_code == 1.0 || operation_code == 2.0) {
        return INVALID;
    }

    let denominator = if operation_code == 0.0 {
        (1.0 / distance_a) + (1.0 / distance_b)
    } else {
        (1.0 / distance_a) - (1.0 / distance_b)
    };
    if denominator == 0.0 {
        return INVALID;
    }
    1.0 / denominator
}
