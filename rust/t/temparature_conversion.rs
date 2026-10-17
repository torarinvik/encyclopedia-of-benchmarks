const MAX_ABS_TEMPERATURE_MICRO: i64 = 1_000_000_000_000;
const MAX_INPUT_LENGTH: usize = 4;
const INVALID_RESULT: f64 = -1.0e300;

fn round_nearest_ties_even(value: f64) -> f64 {
    let lower = value.floor();
    let fraction = value - lower;
    if fraction < 0.5 { return lower; }
    if fraction > 0.5 { return lower + 1.0; }
    let integer = lower as i64;
    if integer % 2 == 0 { lower } else { lower + 1.0 }
}

fn round_digits(value: f64, digits: i64) -> f64 {
    let mut scale = 1.0;
    let magnitude = if digits < 0 { -digits } else { digits };
    for _ in 0..magnitude { scale *= 10.0; }
    let scaled = if digits >= 0 { value * scale } else { value / scale };
    let rounded = round_nearest_ties_even(scaled);
    if digits >= 0 { rounded / scale } else { rounded * scale }
}

#[no_mangle]
pub unsafe extern "C" fn temparature_conversion(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let operation = values[0];
    let temperature_micro = values[1];
    let digits = values[2];
    if length != 3 || !(0..=5).contains(&operation)
        || !(-MAX_ABS_TEMPERATURE_MICRO..=MAX_ABS_TEMPERATURE_MICRO).contains(&temperature_micro)
        || !(-6..=6).contains(&digits) { return INVALID_RESULT; }

    let temperature = temperature_micro as f64 / 1_000_000.0;
    let result = match operation {
        0 => temperature * 1.8 + 32.0,
        1 => temperature + 273.15,
        2 => (temperature - 32.0) * 5.0 / 9.0,
        3 => (temperature - 32.0) * 5.0 / 9.0 + 273.15,
        4 => temperature - 273.15,
        _ => (temperature - 273.15) * 1.8 + 32.0,
    };
    round_digits(result, digits)
}
