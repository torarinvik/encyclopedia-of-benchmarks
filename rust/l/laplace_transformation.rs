const MAX_SAMPLE_COUNT: i64 = 64;
const MAX_INPUT_LENGTH: usize = 68;
const MIN_SAMPLE_MICRO: i64 = -1_000_000;
const MAX_SAMPLE_MICRO: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn laplace_transformation(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let sample_count_value = values[0];
    let s_milli = values[1];
    let dt_micro = values[2];
    if !(1..=MAX_SAMPLE_COUNT).contains(&sample_count_value) { return INVALID_RESULT; }
    let sample_count = sample_count_value as usize;
    if length != sample_count + 3 || !(0..=1000).contains(&s_milli) ||
        !(1..=1_000_000).contains(&dt_micro) { return INVALID_RESULT; }

    let mut samples = [0.0_f64; 64];
    for index in 0..sample_count {
        let sample = values[3 + index];
        if !(MIN_SAMPLE_MICRO..=MAX_SAMPLE_MICRO).contains(&sample) { return INVALID_RESULT; }
        samples[index] = sample as f64 / 1_000_000.0;
    }
    if sample_count == 1 { return 0.0; }

    let s_value = s_milli as f64 / 1000.0;
    let delta_t = dt_micro as f64 / 1_000_000.0;
    let stop = (sample_count - 1) as f64 * delta_t;
    let step = stop / (sample_count - 1) as f64;
    let mut integrand = [0.0_f64; 64];
    for index in 0..sample_count {
        let time = if index == sample_count - 1 { stop } else { index as f64 * step };
        integrand[index] = samples[index] * (-s_value * time).exp();
    }

    let mut result = 0.0;
    for index in 0..sample_count - 1 {
        result += (delta_t * (integrand[index] + integrand[index + 1])) / 2.0;
    }
    result
}
