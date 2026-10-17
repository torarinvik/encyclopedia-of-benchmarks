const MAX_SUPPORT_LENGTH: usize = 4;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 20;
const MAX_OUTPUT_ELEMENTS: usize = 48;

#[no_mangle]
pub unsafe extern "C" fn joint_probability_distribution(
    input: *const f64,
    input_len: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_len < 2 || input_len > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_len);
    let nx_value = values[0];
    let ny_value = values[1];
    if !nx_value.is_finite() || !ny_value.is_finite()
        || nx_value < 1.0 || nx_value > MAX_SUPPORT_LENGTH as f64
        || ny_value < 1.0 || ny_value > MAX_SUPPORT_LENGTH as f64
        || nx_value.fract() != 0.0 || ny_value.fract() != 0.0 {
        return -1;
    }
    let nx = nx_value as usize;
    let ny = ny_value as usize;
    if input_len != 2 + 2 * nx + 2 * ny { return -1; }

    let x_start = 2;
    let y_start = x_start + nx;
    let x_probability_start = y_start + ny;
    let y_probability_start = x_probability_start + nx;
    let mut x_values = [0i64; MAX_SUPPORT_LENGTH];
    let mut y_values = [0i64; MAX_SUPPORT_LENGTH];
    let mut x_probabilities = [0.0f64; MAX_SUPPORT_LENGTH];
    let mut y_probabilities = [0.0f64; MAX_SUPPORT_LENGTH];

    for index in 0..nx {
        let raw = values[x_start + index];
        if !raw.is_finite() || !(-1000.0..=1000.0).contains(&raw) || raw.fract() != 0.0 {
            return -1;
        }
        x_values[index] = raw as i64;
        let probability = values[x_probability_start + index];
        if !probability.is_finite() || !(-1_000_000.0..=1_000_000.0).contains(&probability) {
            return -1;
        }
        x_probabilities[index] = probability;
        if x_values[..index].contains(&x_values[index]) { return -1; }
    }
    for index in 0..ny {
        let raw = values[y_start + index];
        if !raw.is_finite() || !(-1000.0..=1000.0).contains(&raw) || raw.fract() != 0.0 {
            return -1;
        }
        y_values[index] = raw as i64;
        let probability = values[y_probability_start + index];
        if !probability.is_finite() || !(-1_000_000.0..=1_000_000.0).contains(&probability) {
            return -1;
        }
        y_probabilities[index] = probability;
        if y_values[..index].contains(&y_values[index]) { return -1; }
    }

    let required = 3 * nx * ny;
    if required > MAX_OUTPUT_ELEMENTS { return -1; }
    if output.is_null() || output_capacity < required { return -2; }
    for x_index in 0..nx {
        for y_index in 0..ny {
            let position = 3 * (x_index * ny + y_index);
            *output.add(position) = x_values[x_index] as f64;
            *output.add(position + 1) = y_values[y_index] as f64;
            *output.add(position + 2) = x_probabilities[x_index] * y_probabilities[y_index];
        }
    }
    required as i64
}
