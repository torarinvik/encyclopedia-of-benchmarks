const MAX_SAMPLES: i64 = 32;
const SCALE: i64 = 1_000_000;
const MAX_SIGNAL_MICRO: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn complementary_filter(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 || length > 98 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let coefficient_ppm = input[0];
    let sample_count_value = input[1];
    if !(1..SCALE).contains(&coefficient_ppm) || !(1..=MAX_SAMPLES).contains(&sample_count_value) {
        return INVALID_RESULT;
    }
    let sample_count = sample_count_value as usize;
    if length != 2 + 3 * sample_count { return INVALID_RESULT; }
    for sample in 0..sample_count {
        let rate = input[2 + 3 * sample];
        let reference = input[3 + 3 * sample];
        let elapsed = input[4 + 3 * sample];
        if !(-MAX_SIGNAL_MICRO..=MAX_SIGNAL_MICRO).contains(&rate) ||
            !(-MAX_SIGNAL_MICRO..=MAX_SIGNAL_MICRO).contains(&reference) || !(1..=SCALE).contains(&elapsed) {
            return INVALID_RESULT;
        }
    }
    let coefficient = coefficient_ppm as f64 / SCALE as f64;
    let mut value = 0.0;
    for sample in 0..sample_count {
        let rate = input[2 + 3 * sample] as f64 / SCALE as f64;
        let reference = input[3 + 3 * sample] as f64 / SCALE as f64;
        let elapsed = input[4 + 3 * sample] as f64 / SCALE as f64;
        if sample == 0 { value = reference; }
        else { value = coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference; }
    }
    value
}
