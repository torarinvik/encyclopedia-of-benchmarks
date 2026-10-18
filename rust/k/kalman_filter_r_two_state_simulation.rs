const MAX_OBSERVATIONS: usize = 12;
const MAX_PARSEABLE_LENGTH: usize = 64;
const MAX_OUTPUT_ELEMENTS: usize = 30;

fn multiply_2x2(left: &[f64; 4], right: &[f64; 4]) -> [f64; 4] {
    let mut result = [0.0; 4];
    for row in 0..2 {
        for column in 0..2 {
            let mut sum = 0.0;
            for inner in 0..2 {
                sum += left[row * 2 + inner] * right[inner * 2 + column];
            }
            result[row * 2 + column] = sum;
        }
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn kalman_filter_r_two_state_simulation(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_PARSEABLE_LENGTH
        || input_length > MAX_OBSERVATIONS
    {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite() || *value < -1000.0 || *value > 1000.0) {
        return -1;
    }

    let transition = [1.0, 0.0, 1.0, 1.0];
    let transition_t = [1.0, 1.0, 0.0, 1.0];
    let mut state = [values[0], 0.0];
    let mut covariance = [1.0, 0.0, 0.0, 1.0];
    let mut trace = [0.0; 2 * MAX_OBSERVATIONS];
    let mut final_state_pred = [0.0; 2];
    let mut final_covariance_pred = [0.0; 4];

    for step in 0..input_length {
        for i in 0..2 {
            let mut sum = 0.0;
            for j in 0..2 {
                sum += transition[i * 2 + j] * state[j];
            }
            final_state_pred[i] = sum;
        }

        let temp = multiply_2x2(&transition, &covariance);
        final_covariance_pred = multiply_2x2(&temp, &transition_t);
        final_covariance_pred[0] += 0.0001;
        final_covariance_pred[3] += 0.0001;

        let mut h_pred = [0.0; 2];
        for column in 0..2 {
            let mut sum = 0.0;
            sum += 1.0 * final_covariance_pred[column];
            sum += 0.0 * final_covariance_pred[2 + column];
            h_pred[column] = sum;
        }
        let mut innovation = 0.0;
        innovation += h_pred[0] * 1.0;
        innovation += h_pred[1] * 0.0;
        innovation += 0.1;

        let inverse_innovation = 1.0 / innovation;
        let mut gain = [0.0; 2];
        for row in 0..2 {
            let mut projected = 0.0;
            projected += final_covariance_pred[row * 2] * 1.0;
            projected += final_covariance_pred[row * 2 + 1] * 0.0;
            gain[row] = projected * inverse_innovation;
        }
        let mut h_state_pred = 0.0;
        h_state_pred += 1.0 * final_state_pred[0];
        h_state_pred += 0.0 * final_state_pred[1];
        let residual = values[step] - h_state_pred;
        for row in 0..2 {
            state[row] = final_state_pred[row] + gain[row] * residual;
        }
        trace[2 * step] = state[0];
        trace[2 * step + 1] = state[1];

        let gain_observation = [gain[0] * 1.0, gain[0] * 0.0,
                                gain[1] * 1.0, gain[1] * 0.0];
        let mut update = [0.0; 4];
        for i in 0..4 {
            update[i] = 1.0 - gain_observation[i];
        }
        covariance = multiply_2x2(&update, &final_covariance_pred);
    }

    let mut staged = [0.0; MAX_OUTPUT_ELEMENTS];
    let mut out = 0usize;
    for i in 0..2 * input_length {
        staged[out] = trace[i];
        out += 1;
    }
    staged[out] = final_state_pred[0]; out += 1;
    staged[out] = final_state_pred[1]; out += 1;
    staged[out] = final_covariance_pred[0]; out += 1;
    staged[out] = final_covariance_pred[2]; out += 1;
    staged[out] = final_covariance_pred[1]; out += 1;
    staged[out] = final_covariance_pred[3]; out += 1;
    let result_length = out;
    if result_length > MAX_OUTPUT_ELEMENTS || output.is_null() || output_capacity < result_length {
        return -2;
    }
    for i in 0..result_length {
        unsafe { *output.add(i) = staged[i]; }
    }
    result_length as i64
}
