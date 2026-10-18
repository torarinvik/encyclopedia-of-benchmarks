const MAX_SAMPLES: usize = 8;
const MAX_FEATURES: usize = 4;
const MAX_QUERIES: usize = 4;
const MAX_INPUT_LENGTH: usize = 61;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 62;
const MAX_OUTPUT_LENGTH: usize = 13;

#[no_mangle]
pub unsafe extern "C" fn perceptron_java(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(9..=MAX_PARSEABLE_INPUT_LENGTH).contains(&input_length) {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }

    let learning_rate = values[0];
    let epochs_value = values[1];
    let samples_value = values[2];
    let features_value = values[3];
    if learning_rate != 0.25 && learning_rate != 0.5 && learning_rate != 0.75 && learning_rate != 1.0 {
        return -1;
    }
    if !epochs_value.is_finite() || epochs_value < 1.0 || epochs_value > 12.0 || epochs_value.fract() != 0.0 ||
        !samples_value.is_finite() || samples_value < 2.0 || samples_value > MAX_SAMPLES as f64 || samples_value.fract() != 0.0 ||
        !features_value.is_finite() || features_value < 1.0 || features_value > MAX_FEATURES as f64 || features_value.fract() != 0.0 {
        return -1;
    }
    let max_epochs = epochs_value as usize;
    let sample_count = samples_value as usize;
    let feature_count = features_value as usize;
    let features_start = 4;
    let labels_start = features_start + sample_count * feature_count;
    let query_count_index = labels_start + sample_count;
    if input_length <= query_count_index {
        return -1;
    }

    let query_count_value = values[query_count_index];
    if !query_count_value.is_finite() || query_count_value < 1.0 ||
        query_count_value > MAX_QUERIES as f64 || query_count_value.fract() != 0.0 {
        return -1;
    }
    let query_count = query_count_value as usize;
    let query_start = query_count_index + 1;
    if input_length != query_start + query_count * feature_count || input_length > MAX_INPUT_LENGTH {
        return -1;
    }

    for row in 0..sample_count {
        for feature in 0..feature_count {
            let value = values[features_start + row * feature_count + feature];
            if !value.is_finite() || value < -2.0 || value > 2.0 || value.fract() != 0.0 {
                return -1;
            }
        }
    }
    for row in 0..sample_count {
        let label = values[labels_start + row];
        if label != 0.0 && label != 1.0 {
            return -1;
        }
    }
    for row in 0..query_count {
        for feature in 0..feature_count {
            let value = values[query_start + row * feature_count + feature];
            if !value.is_finite() || value < -2.0 || value > 2.0 || value.fract() != 0.0 {
                return -1;
            }
        }
    }

    let mut weights = [0.0_f64; MAX_FEATURES];
    let mut bias = 0.0;
    let mut epochs_run = 0;
    let mut converged = false;
    for epoch in 0..max_epochs {
        let mut updated = false;
        for row in 0..sample_count {
            let mut weighted_sum = bias;
            for feature in 0..feature_count {
                weighted_sum += weights[feature] * values[features_start + row * feature_count + feature];
            }
            let prediction = if weighted_sum >= 0.0 { 1_i32 } else { 0_i32 };
            let label = values[labels_start + row] as i32;
            let error = label - prediction;
            if error != 0 {
                for feature in 0..feature_count {
                    weights[feature] += learning_rate * error as f64 * values[features_start + row * feature_count + feature];
                }
                bias += learning_rate * error as f64;
                updated = true;
            }
        }
        epochs_run = epoch + 1;
        if !updated {
            converged = true;
            break;
        }
    }

    let mut staged = [0.0_f64; MAX_OUTPUT_LENGTH];
    let mut result_length = 0;
    staged[result_length] = feature_count as f64;
    result_length += 1;
    for feature in 0..feature_count {
        staged[result_length] = weights[feature];
        result_length += 1;
    }
    staged[result_length] = bias;
    result_length += 1;
    staged[result_length] = epochs_run as f64;
    result_length += 1;
    staged[result_length] = if converged { 1.0 } else { 0.0 };
    result_length += 1;
    staged[result_length] = query_count as f64;
    result_length += 1;
    for row in 0..query_count {
        let mut weighted_sum = bias;
        for feature in 0..feature_count {
            weighted_sum += weights[feature] * values[query_start + row * feature_count + feature];
        }
        staged[result_length] = if weighted_sum >= 0.0 { 1.0 } else { 0.0 };
        result_length += 1;
    }

    if output.is_null() || output_capacity < result_length {
        return -2;
    }
    for index in 0..result_length {
        unsafe { *output.add(index) = staged[index]; }
    }
    result_length as i64
}
