const INVALID_RESULT: f64 = -1.0e300;
const MAX_SPEED_MICRO: i64 = 1_000_000_000_000_000;
const MAX_ROUNDED_MILLI: f64 = 9_007_199_254_740_992.0;
const TO_KMH: [f64; 7] = [1.0, 3.6, 1.609344, 1.852, 1.09728, 1225.08, 1_079_252_848.8];
const FROM_KMH: [f64; 7] = [1.0, 0.277777778, 0.621371192, 0.539956803,
                            0.911344415, 0.000816164, 9.265669311e-10];

fn round_three_away(scaled: f64) -> f64 {
    if scaled == 0.0 { return scaled / 1000.0; }
    let negative = scaled < 0.0;
    let magnitude = if negative { -scaled } else { scaled };
    let mut rounded_milli = magnitude as u64;
    if magnitude - rounded_milli as f64 >= 0.5 { rounded_milli += 1; }
    let rounded = rounded_milli as f64 / 1000.0;
    if negative { -rounded } else { rounded }
}

#[no_mangle]
pub unsafe extern "C" fn speed(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 3 { return INVALID_RESULT; }
    let speed_micro = *values;
    let from_unit = *values.add(1);
    let to_unit = *values.add(2);
    if !(-MAX_SPEED_MICRO..=MAX_SPEED_MICRO).contains(&speed_micro)
        || !(0..=6).contains(&from_unit) || !(0..=6).contains(&to_unit) {
        return INVALID_RESULT;
    }
    let speed_value = speed_micro as f64 / 1_000_000.0;
    let kmh = speed_value * TO_KMH[from_unit as usize];
    let result = kmh * FROM_KMH[to_unit as usize];
    let scaled = result * 1000.0;
    if scaled > MAX_ROUNDED_MILLI || scaled < -MAX_ROUNDED_MILLI { return INVALID_RESULT; }
    round_three_away(scaled)
}
