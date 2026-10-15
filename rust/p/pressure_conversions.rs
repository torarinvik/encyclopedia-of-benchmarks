fn from_factor(code: f64) -> f64 {
    match code {
        0.0 => 1.0,
        1.0 => 0.0000098,
        2.0 => 0.986923,
        3.0 => 0.00986923,
        4.0 => 9.86923,
        5.0 => 0.068046,
        6.0 => 0.0334211,
        7.0 => 0.00131579,
        _ => 0.0,
    }
}

fn to_factor(code: f64) -> f64 {
    match code {
        0.0 => 1.0,
        1.0 => 101325.0,
        2.0 => 1.01325,
        3.0 => 101.325,
        4.0 => 0.101325,
        5.0 => 14.6959,
        6.0 => 29.9213,
        7.0 => 760.0,
        _ => 0.0,
    }
}

#[no_mangle]
pub extern "C" fn pressure_conversions(value: f64, from_code: f64, to_code: f64) -> f64 {
    if !value.is_finite() || value < -1_000_000.0 || value > 1_000_000.0 {
        return -1.0;
    }
    let source = from_factor(from_code);
    let target = to_factor(to_code);
    if source == 0.0 || target == 0.0 {
        return -1.0;
    }
    let scaled = value * source;
    scaled * target
}
