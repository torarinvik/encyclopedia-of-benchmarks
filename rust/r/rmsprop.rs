const MAX_VECTOR_LENGTH: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 102;

#[no_mangle]
pub unsafe extern "C" fn rmsprop(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let count_value = values[0];
    if !count_value.is_finite() || count_value.fract() != 0.0 || count_value < 0.0 || count_value > MAX_VECTOR_LENGTH as f64 {
        return -1;
    }
    let count = count_value as usize;
    let mode_value = values[1];
    if mode_value != 0.0 && mode_value != 1.0 {
        return -1;
    }
    let mode = mode_value as usize;
    if input_length != 5 + 2 * count + if mode == 1 { count } else { 0 } {
        return -1;
    }

    let learning_rate = values[2];
    let rho = values[3];
    let epsilon = values[4];
    if !learning_rate.is_finite() || !(1e-6..=1.0).contains(&learning_rate) {
        return -1;
    }
    if !rho.is_finite() || !(0.0..=0.99).contains(&rho) {
        return -1;
    }
    if !epsilon.is_finite() || !(1e-8..=1.0).contains(&epsilon) {
        return -1;
    }

    let mut params = [0.0_f64; MAX_VECTOR_LENGTH];
    let mut gradients = [0.0_f64; MAX_VECTOR_LENGTH];
    let mut moving_avg = [0.0_f64; MAX_VECTOR_LENGTH];
    for index in 0..count {
        let param = values[5 + index];
        let gradient = values[5 + count + index];
        if !param.is_finite() || !(-100.0..=100.0).contains(&param) {
            return -1;
        }
        if !gradient.is_finite() || !(-100.0..=100.0).contains(&gradient) {
            return -1;
        }
        params[index] = param;
        gradients[index] = gradient;
    }
    if mode == 1 {
        for index in 0..count {
            let value = values[5 + 2 * count + index];
            if !value.is_finite() || !(0.0..=10_000.0).contains(&value) {
                return -1;
            }
            moving_avg[index] = value;
        }
    }
    if output.is_null() || output_capacity < 2 * count {
        return -2;
    }

    for index in 0..count {
        let gradient = gradients[index];
        let updated_avg = rho * moving_avg[index] + (1.0 - rho) * (gradient * gradient);
        moving_avg[index] = updated_avg;
        params[index] = params[index] - (learning_rate / (updated_avg + epsilon).sqrt()) * gradient;
    }
    for index in 0..count {
        unsafe {
            *output.add(index) = params[index];
            *output.add(count + index) = moving_avg[index];
        }
    }
    (2 * count) as i64
}
