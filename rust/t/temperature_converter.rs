const MAX_ABS_TEMPERATURE_MICRO: i64 = 1_000_000_000_000;
const MAX_INPUT_LENGTH: usize = 3;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn temperature_converter(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let operation = *values;
    let temperature_micro = *values.add(1);
    if temperature_micro < -MAX_ABS_TEMPERATURE_MICRO || temperature_micro > MAX_ABS_TEMPERATURE_MICRO {
        return INVALID_RESULT;
    }
    let temperature = temperature_micro as f64 / 1_000_000.0;
    match operation {
        0 => temperature * 9.0 / 5.0 + 32.0,
        1 => temperature + 273.15,
        2 => (temperature - 32.0) * 5.0 / 9.0,
        3 => (temperature - 32.0) * 5.0 / 9.0 + 273.15,
        4 => temperature - 273.15,
        5 => (temperature - 273.15) * 9.0 / 5.0 + 32.0,
        _ => INVALID_RESULT,
    }
}
