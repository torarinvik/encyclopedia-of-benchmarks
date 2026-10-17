const MAX_PARSEABLE_INPUT_LENGTH: usize = 45;
const MAX_SAMPLES: usize = 8;
const MAX_FEATURES: usize = 4;
const MAX_FEATURE_VALUES: usize = MAX_SAMPLES * MAX_FEATURES;

#[no_mangle]
pub unsafe extern "C" fn linear_regression_vectorized(
    input: *const f64,
    length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (sample_value, feature_value, iteration_value) = (values[0], values[1], values[2]);
    if sample_value.is_nan() || !(2.0..=MAX_SAMPLES as f64).contains(&sample_value) ||
        feature_value.is_nan() || !(2.0..=MAX_FEATURES as f64).contains(&feature_value) ||
        iteration_value.is_nan() || !(10.0..=128.0).contains(&iteration_value) { return -1; }
    let sample_count = sample_value as usize;
    let feature_count = feature_value as usize;
    let iterations = iteration_value as usize;
    if sample_count as f64 != sample_value || feature_count as f64 != feature_value ||
        iterations as f64 != iteration_value { return -1; }
    if length != 4 + sample_count * feature_count + sample_count { return -1; }

    let alpha = values[3];
    if alpha.is_nan() || !(0.0001..=0.01).contains(&alpha) { return -1; }

    let mut features = [0.0f64; MAX_FEATURE_VALUES];
    let mut labels = [0.0f64; MAX_SAMPLES];
    let feature_values = sample_count * feature_count;
    for index in 0..feature_values {
        let value = values[4 + index];
        if value.is_nan() || !(-1.0..=1.0).contains(&value) { return -1; }
        features[index] = value;
    }
    for row in 0..sample_count {
        if features[row * feature_count] != 1.0 { return -1; }
    }
    for row in 0..sample_count {
        let value = values[4 + feature_values + row];
        if value.is_nan() || !(-1.0..=1.0).contains(&value) { return -1; }
        labels[row] = value;
    }
    if output.is_null() || output_capacity < feature_count { return -2; }

    let mut theta = [0.0f64; MAX_FEATURES];
    let mut errors = [0.0f64; MAX_SAMPLES];
    let mut gradients = [0.0f64; MAX_FEATURES];
    for _ in 0..iterations {
        for row in 0..sample_count {
            let mut prediction = 0.0;
            for column in 0..feature_count {
                prediction += features[row * feature_count + column] * theta[column];
            }
            errors[row] = prediction - labels[row];
        }
        for column in 0..feature_count {
            let mut gradient = 0.0;
            for row in 0..sample_count {
                gradient += features[row * feature_count + column] * errors[row];
            }
            gradients[column] = gradient / sample_count as f64;
        }
        for column in 0..feature_count { theta[column] -= alpha * gradients[column]; }
    }
    std::ptr::copy_nonoverlapping(theta.as_ptr(), output, feature_count);
    feature_count as i64
}
