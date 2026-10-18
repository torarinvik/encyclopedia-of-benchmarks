const MAX_SAMPLES: usize = 8;
const MAX_FEATURES: usize = 3;
const MAX_INPUT: usize = 101;

#[no_mangle]
pub unsafe extern "C" fn mini_batch_gradient_descent(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(5..=MAX_INPUT).contains(&input_length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|x| !x.is_finite()) { return -1; }
    if values[0] < 1.0 || values[0] > MAX_SAMPLES as f64 ||
       values[1] < 1.0 || values[1] > MAX_FEATURES as f64 { return -1; }
    let samples = values[0] as usize;
    let features = values[1] as usize;
    if values[0].fract() != 0.0 || values[1].fract() != 0.0 ||
       values[2] < 1.0 || values[2] > samples as f64 ||
       values[3] < 0.0 || values[3] > 8.0 { return -1; }
    let batch_size = values[2] as usize;
    let epochs = values[3] as usize;
    if values[2].fract() != 0.0 || values[3].fract() != 0.0 { return -1; }
    let learning_rate = values[4];
    if !(0.0..=0.25).contains(&learning_rate) { return -1; }
    let matrix_start = 5;
    let matrix_end = matrix_start + samples * features;
    let targets_end = matrix_end + samples;
    if input_length != targets_end + epochs * samples { return -1; }

    let mut matrix = [0.0; MAX_SAMPLES * MAX_FEATURES];
    let mut targets = [0.0; MAX_SAMPLES];
    for i in 0..samples*features {
        let x = values[matrix_start+i];
        if !(-10.0..=10.0).contains(&x) { return -1; }
        matrix[i] = x;
    }
    for i in 0..samples {
        let y = values[matrix_end+i];
        if !(-100.0..=100.0).contains(&y) { return -1; }
        targets[i] = y;
    }
    let mut orders = [[0usize; MAX_SAMPLES]; 8];
    for epoch in 0..epochs {
        let mut seen = [false; MAX_SAMPLES];
        for pos in 0..samples {
            let value = values[targets_end + epoch*samples + pos];
            if value < 0.0 || value >= samples as f64 || value.fract() != 0.0 { return -1; }
            let index = value as usize;
            if seen[index] { return -1; }
            seen[index] = true;
            orders[epoch][pos] = index;
        }
    }

    let mut weights = [0.0; MAX_FEATURES];
    let mut bias = 0.0;
    for epoch in 0..epochs {
        let mut start = 0;
        while start < samples {
            let length = (samples-start).min(batch_size);
            let mut errors = [0.0; MAX_SAMPLES];
            for pos in 0..length {
                let sample = orders[epoch][start+pos];
                let mut prediction = 0.0;
                for feature in 0..features {
                    let product = matrix[sample*features+feature] * weights[feature];
                    if !product.is_finite() { return -1; }
                    prediction += product;
                    if !prediction.is_finite() { return -1; }
                }
                prediction += bias;
                if !prediction.is_finite() { return -1; }
                errors[pos] = prediction - targets[sample];
                if !errors[pos].is_finite() { return -1; }
            }
            for feature in 0..features {
                let mut gradient = 0.0;
                for pos in 0..length {
                    let sample = orders[epoch][start+pos];
                    let product = matrix[sample*features+feature] * errors[pos];
                    if !product.is_finite() { return -1; }
                    gradient += product;
                    if !gradient.is_finite() { return -1; }
                }
                let update = (learning_rate * gradient) / length as f64;
                if !update.is_finite() { return -1; }
                weights[feature] -= update;
                if !weights[feature].is_finite() { return -1; }
            }
            let mut error_sum = 0.0;
            for pos in 0..length {
                error_sum += errors[pos];
                if !error_sum.is_finite() { return -1; }
            }
            let mean_error = error_sum / length as f64;
            if !mean_error.is_finite() { return -1; }
            let bias_update = learning_rate * mean_error;
            if !bias_update.is_finite() { return -1; }
            bias -= bias_update;
            if !bias.is_finite() { return -1; }
            start += length;
        }
    }
    let mut staged = [0.0; MAX_FEATURES+1];
    for i in 0..features { staged[i] = weights[i]; }
    staged[features] = bias;
    let result_length = features + 1;
    if output.is_null() || output_capacity < result_length { return -2; }
    for i in 0..result_length { unsafe { *output.add(i) = staged[i]; } }
    result_length as i64
}
