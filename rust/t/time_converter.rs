const SCALE: i64 = 1_000_000;
const MAX_TIME_MICRO: i64 = 1_000_000_000;
const MAX_INPUT_LENGTH: usize = 4;
const INVALID_RESULT: f64 = -1.0e300;

fn seconds_per_unit(unit: i64) -> f64 {
    match unit {
        0 => 1.0,
        1 => 60.0,
        2 => 3600.0,
        3 => 86400.0,
        4 => 604800.0,
        5 => 2629800.0,
        6 => 31557600.0,
        _ => 0.0,
    }
}

#[no_mangle]
pub unsafe extern "C" fn time_converter(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let time_micro = *values;
    let from_unit = *values.add(1);
    let to_unit = *values.add(2);
    if time_micro < 0 || time_micro > MAX_TIME_MICRO || from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6 { return INVALID_RESULT; }
    let time_value = time_micro as f64 / SCALE as f64;
    let seconds_value = time_value * seconds_per_unit(from_unit);
    let converted = seconds_value / seconds_per_unit(to_unit);
    let rounded = (converted * 1000.0 + 0.5) as i64;
    rounded as f64 / 1000.0
}
