const MAX_VALUE: f64 = 1_000_000.0;

fn to_pascal_factor(code: f64) -> f64 {
    match code {
        0.0 => 1.0,
        1.0 => 1000.0,
        2.0 => 1_000_000.0,
        3.0 => 100_000.0,
        4.0 => 101_325.0,
        5.0 => 6894.757293168,
        _ => 0.0,
    }
}

/// Convert pressure using Pascal as the intermediate unit.
#[no_mangle]
pub extern "C" fn pressure(value: f64, from_unit_code: f64, to_unit_code: f64) -> f64 {
    if !value.is_finite() || value < -MAX_VALUE || value > MAX_VALUE { return -1.0; }
    let from_factor = to_pascal_factor(from_unit_code);
    let to_factor = to_pascal_factor(to_unit_code);
    if from_factor == 0.0 || to_factor == 0.0 { return -1.0; }
    let pascals = value * from_factor;
    pascals / to_factor
}
