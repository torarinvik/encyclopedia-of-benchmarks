const MAX_VALUE: f64 = 1e100;

fn unit_exponent(code: f64) -> i32 {
    match code {
        0.0 => 0,
        1.0 => 3,
        2.0 => 6,
        3.0 => 9,
        4.0 => 12,
        5.0 => 15,
        6.0 => 18,
        7.0 => 21,
        8.0 => 24,
        _ => -1,
    }
}

/// Preserve the source formula and operation order: value * 10.powi(from - to).
#[no_mangle]
pub extern "C" fn order_of_magnitude_conversion(value: f64, from_unit_code: f64, to_unit_code: f64) -> f64 {
    if !value.is_finite() || value < -MAX_VALUE || value > MAX_VALUE {
        return -1.0;
    }
    let from_exp = unit_exponent(from_unit_code);
    let to_exp = unit_exponent(to_unit_code);
    if from_exp < 0 || to_exp < 0 {
        return -1.0;
    }
    value * 10.0_f64.powi(from_exp - to_exp)
}
