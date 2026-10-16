/// Selected entry in the Haskell complementary-filter scan trace.
const MAX_SAMPLES: i64 = 32;
const SCALE: i64 = 1_000_000;
const MAX_SIGNAL_MICRO: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn comp_filt(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 6 || length > 68 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let alpha_ppm = input[0];
    let delta_t_micro = input[1];
    let count_value = input[2];
    let output_index_value = input[3];
    if !(0..=SCALE).contains(&alpha_ppm) || !(0..=SCALE).contains(&delta_t_micro) ||
        !(1..=MAX_SAMPLES).contains(&count_value) || output_index_value < 0 || output_index_value > count_value {
        return INVALID_RESULT;
    }
    let count = count_value as usize;
    let output_index = output_index_value as usize;
    if length != 4 + 2 * count { return INVALID_RESULT; }
    let rates = &input[4..4 + count];
    let references = &input[4 + count..];
    if rates.iter().chain(references.iter()).any(|value| !(-MAX_SIGNAL_MICRO..=MAX_SIGNAL_MICRO).contains(value)) {
        return INVALID_RESULT;
    }
    let alpha = alpha_ppm as f64 / SCALE as f64;
    let delta_t = delta_t_micro as f64 / SCALE as f64;
    let mut theta = references[0] as f64 / SCALE as f64;
    for i in 0..output_index {
        let rate = rates[i] as f64 / SCALE as f64;
        let reference = references[i] as f64 / SCALE as f64;
        theta = alpha * (theta + rate * delta_t) + (1.0 - alpha) * reference;
    }
    theta
}
