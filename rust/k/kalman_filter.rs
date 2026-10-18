/// Run Java's scalar filter cycle and report state after every measurement.
const MAX_STEPS: usize = 12;
const MAX_PARSEABLE_LENGTH: usize = 64;
const SCALE: f64 = 1_000_000.0;

#[no_mangle]
pub unsafe extern "C" fn kalman_filter(
    input: *const f64,
    length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values.iter().any(|value| !value.is_finite() || value.trunc() != *value) { return -1; }
    let raw_steps = values[4];
    if raw_steps < 1.0 || raw_steps > MAX_STEPS as f64 { return -1; }
    let steps = raw_steps as usize;
    if length != 5 + steps { return -1; }
    if values[0] < -1_000_000_000.0 || values[0] > 1_000_000_000.0 ||
        values[1] < 0.0 || values[1] > 1_000_000_000_000.0 ||
        values[2] < 0.0 || values[2] > 1_000_000_000_000.0 ||
        values[3] < 1.0 || values[3] > 1_000_000_000_000.0 { return -1; }
    for measurement in &values[5..] {
        if *measurement < -1_000_000_000.0 || *measurement > 1_000_000_000.0 { return -1; }
    }

    let required = 3 * steps;
    if output.is_null() || output_capacity < required { return -2; }
    let mut estimate = values[0] / SCALE;
    let mut covariance = values[1] / SCALE;
    let process_noise = values[2] / SCALE;
    let measurement_noise = values[3] / SCALE;
    for step in 0..steps {
        let measurement = values[5 + step] / SCALE;
        estimate += 0.0;
        covariance += process_noise;
        let innovation_variance = covariance + measurement_noise;
        let gain = covariance / innovation_variance;
        estimate += gain * (measurement - estimate);
        covariance = covariance * measurement_noise / innovation_variance;
        unsafe {
            *output.add(3 * step) = estimate;
            *output.add(3 * step + 1) = covariance;
            *output.add(3 * step + 2) = gain;
        }
    }
    required as i64
}
