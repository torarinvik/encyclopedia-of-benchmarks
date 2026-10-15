const MAX_STEPS: usize = 256;
const MAX_PARAMETERS: usize = 16;
const INPUT_SCALE: f64 = 1_000_000_000.0;
const OUTPUT_SCALE: f64 = 1_000_000.0;

fn adam_sqrt(value: f64) -> f64 {
    if value <= 0.0 { return 0.0; }
    let mut root = if value > 1.0 { value } else { 1.0 };
    for _ in 0..80 { root = 0.5 * (root + value / root); }
    root
}

#[no_mangle]
pub unsafe extern "C" fn adam(input: *const i64, length: usize,
                               output: *mut u8, output_capacity: usize) -> i64 {
    let max_input_length = 7 + MAX_PARAMETERS + MAX_STEPS * MAX_PARAMETERS;
    if input.is_null() || length < 9 || length > max_input_length { return -1; }
    let steps_value = *input;
    let parameter_count_value = *input.add(1);
    let learning_rate_value = *input.add(2);
    let beta1_value = *input.add(3);
    let beta2_value = *input.add(4);
    let epsilon_value = *input.add(5);
    let weight_decay_value = *input.add(6);
    if steps_value < 1 || steps_value > MAX_STEPS as i64 || parameter_count_value < 1 ||
        parameter_count_value > MAX_PARAMETERS as i64 { return -1; }
    let steps = steps_value as usize;
    let parameter_count = parameter_count_value as usize;
    if length != 7 + parameter_count + steps * parameter_count ||
        learning_rate_value < 1 || learning_rate_value > 1_000_000_000 ||
        beta1_value < 0 || beta1_value >= 1_000_000_000 || beta2_value < 0 || beta2_value >= 1_000_000_000 ||
        epsilon_value < 1 || epsilon_value > 10_000_000 || weight_decay_value < 0 || weight_decay_value > 100_000_000 { return -1; }
    for i in 0..parameter_count {
        let parameter = *input.add(7 + i);
        if parameter < -1_000_000_000_000_000 || parameter > 1_000_000_000_000_000 { return -1; }
    }
    let gradient_start = 7 + parameter_count;
    for i in 0..steps * parameter_count {
        let gradient = *input.add(gradient_start + i);
        if gradient < -1_000_000_000_000 || gradient > 1_000_000_000_000 { return -1; }
    }
    let output_count = steps * parameter_count;
    if output.is_null() || output_capacity < 8 * output_count { return -2; }

    let learning_rate = learning_rate_value as f64 / INPUT_SCALE;
    let beta1 = beta1_value as f64 / INPUT_SCALE;
    let beta2 = beta2_value as f64 / INPUT_SCALE;
    let epsilon = epsilon_value as f64 / INPUT_SCALE;
    let weight_decay = weight_decay_value as f64 / INPUT_SCALE;
    let mut parameters = [0.0f64; MAX_PARAMETERS];
    let mut first_moment = [0.0f64; MAX_PARAMETERS];
    let mut second_moment = [0.0f64; MAX_PARAMETERS];
    for i in 0..parameter_count { parameters[i] = *input.add(7 + i) as f64 / INPUT_SCALE; }
    let mut beta1_power = 1.0;
    let mut beta2_power = 1.0;
    for step in 0..steps {
        beta1_power *= beta1;
        beta2_power *= beta2;
        for i in 0..parameter_count {
            let gradient = *input.add(gradient_start + step * parameter_count + i) as f64 / INPUT_SCALE;
            first_moment[i] = beta1 * first_moment[i] + (1.0 - beta1) * gradient;
            second_moment[i] = beta2 * second_moment[i] + (1.0 - beta2) * (gradient * gradient);
            let corrected_first = first_moment[i] / (1.0 - beta1_power);
            let corrected_second = second_moment[i] / (1.0 - beta2_power);
            let updated = parameters[i] - learning_rate * corrected_first /
                (adam_sqrt(corrected_second) + epsilon) - learning_rate * weight_decay * parameters[i];
            parameters[i] = updated;
            let encoded = (updated * OUTPUT_SCALE) as i64 as u64;
            let output_index = step * parameter_count + i;
            for byte in 0..8 { *output.add(8 * output_index + byte) = (encoded >> (8 * byte)) as u8; }
        }
    }
    output_count as i64
}
