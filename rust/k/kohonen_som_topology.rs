const MAX_INPUT_LENGTH: usize = 56;
const MAX_MAP_SIZE: usize = 4;
const MAX_FEATURE_COUNT: usize = 3;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn kohonen_som_topology(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 4 || input_length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    if exact_integer(values[0], 1, MAX_MAP_SIZE as i64).is_none()
        || exact_integer(values[1], 1, MAX_FEATURE_COUNT as i64).is_none()
        || exact_integer(values[2], 0, 8).is_none()
        || exact_integer(values[3], 1, 16).is_none()
    {
        return -1;
    }
    let map_size = values[0] as usize;
    let feature_count = values[1] as usize;
    let radius = values[2] as usize;
    let alpha_code = values[3] as usize;
    let cell_count = map_size * map_size;
    let weight_count = cell_count * feature_count;
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
    let mut weights = [0.0_f64; 48];
    for index in 0..weight_count {
        let value = values[4 + feature_count + index];
        if exact_integer(value, -8, 8).is_none() {
            return -1;
        }
        weights[index] = value;
    }

    let mut best_matching_unit = 0;
    let mut best_distance_squared = 0.0_f64;
    for feature in 0..feature_count {
        let difference = weights[feature] - sample[feature];
        best_distance_squared += difference * difference;
    }
    let mut best_distance = best_distance_squared.sqrt();
    for cell in 1..cell_count {
        let mut distance_squared = 0.0_f64;
        for feature in 0..feature_count {
            let difference = weights[cell * feature_count + feature] - sample[feature];
            distance_squared += difference * difference;
        }
        let distance = distance_squared.sqrt();
        if distance < best_distance {
            best_distance = distance;
            best_matching_unit = cell;
        }
    }

    let best_x = best_matching_unit / map_size;
    let best_y = best_matching_unit % map_size;
    let first_x = best_x.saturating_sub(radius);
    let after_x = map_size.min(best_x + radius + 1);
    let first_y = best_y.saturating_sub(radius);
    let after_y = map_size.min(best_y + radius + 1);
    let alpha = alpha_code as f64 / 16.0;
    for x in first_x..after_x {
        for y in first_y..after_y {
            let dx = best_x.abs_diff(x);
            let dy = best_y.abs_diff(y);
            let grid_distance_squared = (dx * dx + dy * dy) as f64;
            let scale = (-grid_distance_squared / (2.0 * alpha * alpha)).exp();
            for feature in 0..feature_count {
                let index = (x * map_size + y) * feature_count + feature;
                let difference = sample[feature] - weights[index];
                weights[index] += alpha * scale * difference;
                if !weights[index].is_finite() {
                    return -1;
                }
            }
        }
    }

    let output_length = 1 + weight_count;
    if output.is_null() || output_capacity < output_length {
        return -2;
    }
    *output = best_distance;
    for index in 0..weight_count {
        *output.add(index + 1) = weights[index];
    }
    output_length as i64
}
