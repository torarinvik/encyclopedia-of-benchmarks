const SCALE: i64 = 1_000_000;
const MAX_ABS_TEMPERATURE_MICRO: i64 = 1_000_000_000_000;
const MAX_INPUT_LENGTH: usize = 3;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn temperature_conversions(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let operation = *values;
    let micro = *values.add(1);
    if micro < -MAX_ABS_TEMPERATURE_MICRO || micro > MAX_ABS_TEMPERATURE_MICRO { return INVALID_RESULT; }
    match operation {
        0 if micro % 5_000_000 == 0 => (9 * (micro / 5_000_000) + 32) as f64,
        1 if (micro - 32_000_000) % 9_000_000 == 0 =>
            (5 * ((micro - 32_000_000) / 9_000_000)) as f64,
        2 if micro % SCALE == 0 => (micro / SCALE) as f64 + 273.15,
        3 if (micro - 273_150_000) % SCALE == 0 => ((micro - 273_150_000) / SCALE) as f64,
        4 if (micro - 273_150_000) % 5_000_000 == 0 =>
            (9 * ((micro - 273_150_000) / 5_000_000) + 32) as f64,
        _ => INVALID_RESULT,
    }
}
