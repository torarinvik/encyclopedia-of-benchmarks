const MAX_INPUT_LENGTH: usize = 41;
const MAX_NODE_COUNT: usize = 8;
const MAX_FEATURE_COUNT: usize = 4;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn kohonen_som_trace(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 4 || input_length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    if exact_integer(values[0], 1, MAX_NODE_COUNT as i64).is_none()
        || exact_integer(values[1], 1, MAX_FEATURE_COUNT as i64).is_none()
        || exact_integer(values[2], 0, 8).is_none()
        || exact_integer(values[3], 1, 16).is_none()
    {
        return -1;
    }
    let node_count = values[0] as usize;
    let feature_count = values[1] as usize;
    let radius = values[2] as usize;
    let alpha_code = values[3] as usize;
    let weight_count = node_count * feature_count;
    if input_length != 4 + feature_count + weight_count {
        return -1;
    }

    let mut sample = [0.0_f64; MAX_FEATURE_COUNT];
    for feature in 0..feature_count {
        let value = values[4 + feature];
        if exact_integer(value, -8, 8).is_none() {
            return -1;
        }
        sample[feature] = value;
    }
    let mut weights = [0.0_f64; 32];
    for index in 0..weight_count {
        let value = values[4 + feature_count + index];
        if exact_integer(value, -8, 8).is_none() {
            return -1;
        }
        weights[index] = value;
    }

    let mut best_matching_unit = 0;
    let mut best_distance = 0.0_f64;
    for feature in 0..feature_count {
        let difference = weights[feature] - sample[feature];
        best_distance += difference * difference;
    }
    for node in 1..node_count {
        let mut distance = 0.0_f64;
        for feature in 0..feature_count {
            let difference = weights[node * feature_count + feature] - sample[feature];
            distance += difference * difference;
        }
        if distance < best_distance {
            best_distance = distance;
            best_matching_unit = node;
        }
    }

    let first_node = best_matching_unit.saturating_sub(radius);
    let after_last_node = node_count.min(best_matching_unit + radius + 1);
    let alpha = alpha_code as f64 / 16.0;
    for node in first_node..after_last_node {
        for feature in 0..feature_count {
            let index = node * feature_count + feature;
            let difference = sample[feature] - weights[index];
            weights[index] += alpha * difference;
            if !weights[index].is_finite() {
                return -1;
            }
        }
    }

    if output.is_null() || output_capacity < weight_count {
        return -2;
    }
    for index in 0..weight_count {
        *output.add(index) = weights[index];
    }
    weight_count as i64
}
