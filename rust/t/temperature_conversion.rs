const INVALID_RESULT: i64 = i64::MIN;

fn convert_temperature(operation: i64, value: f64) -> f64 {
    match operation {
        0 => (value * 9.0) / 5.0 + 32.0,
        1 => value + 273.15,
        2 => (value * 9.0) / 5.0 + 491.67,
        3 => ((value - 32.0) * 5.0) / 9.0,
        4 => ((value - 32.0) * 5.0) / 9.0 + 273.15,
        5 => value + 459.67,
        6 => value - 273.15,
        7 => ((value - 273.15) * 9.0) / 5.0 + 32.0,
        8 => (value * 9.0) / 5.0,
        9 => ((value - 491.67) * 5.0) / 9.0,
        10 => value - 459.67,
        11 => (value * 5.0) / 9.0,
        12 => value * 1.25,
        13 => value * 2.25 + 32.0,
        14 => value * 1.25 + 273.15,
        _ => value * 2.25 + 32.0 + 459.67,
    }
}

#[no_mangle]
pub unsafe extern "C" fn temperature_conversion(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let input = std::slice::from_raw_parts(values, length);
    let operation = input[0];
    let temperature = input[1];
    if !(0..=15).contains(&operation) || !(-1_000_000..=1_000_000).contains(&temperature) { return INVALID_RESULT; }
    (convert_temperature(operation, temperature as f64) + 0.5).floor() as i64
}
