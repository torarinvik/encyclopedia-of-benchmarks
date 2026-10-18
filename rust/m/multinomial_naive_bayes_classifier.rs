/// Fit and batch-predict with a bounded multinomial Naive Bayes model.
#[no_mangle]
pub unsafe extern "C" fn multinomial_naive_bayes_classifier(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > 360 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    let fit_count_value = values[0];
    if !(1..=2).contains(&fit_count_value) {
        return -1;
    }
    let fit_count = fit_count_value as usize;
    let mut position = 1usize;
    let mut feature_width = 0usize;
    let mut training_rows = 0i64;
    let mut class_counts = [0i64; 8];
    let mut feature_sums = [0.0f64; 64];
    let mut class_totals = [0.0f64; 8];
    let mut labels = [0i64; 16];
    let mut training_features = [0i64; 128];

    for _ in 0..fit_count {
        if position + 2 > input_length {
            return -1;
        }
        let rows_value = values[position];
        position += 1;
        let width_value = values[position];
        position += 1;
        if !(1..=16).contains(&rows_value) || !(1..=8).contains(&width_value) {
            return -1;
        }
        let rows = rows_value as usize;
        let width = width_value as usize;
        if position + rows + rows * width > input_length {
            return -1;
        }
        for row in 0..rows {
            let label = values[position];
            position += 1;
            if !(0..=7).contains(&label) {
                return -1;
            }
            labels[row] = label;
        }
        for index in 0..rows * width {
            let count = values[position];
            position += 1;
            if !(0..=100).contains(&count) {
                return -1;
            }
            training_features[index / width * 8 + index % width] = count;
        }

        class_counts = [0i64; 8];
        feature_sums = [0.0f64; 64];
        class_totals = [0.0f64; 8];
        training_rows = rows_value;
        feature_width = width;
        for row in 0..rows {
            let label = labels[row] as usize;
            class_counts[label] += 1;
            for column in 0..width {
                let count = training_features[row * 8 + column] as f64;
                feature_sums[label * 8 + column] += count;
                class_totals[label] += count;
            }
        }
    }

    if position + 2 > input_length {
        return -1;
    }
    let prediction_count_value = values[position];
    position += 1;
    let prediction_width_value = values[position];
    position += 1;
    if !(1..=8).contains(&prediction_count_value)
        || !(1..=8).contains(&prediction_width_value)
        || prediction_width_value as usize != feature_width
    {
        return -1;
    }
    let prediction_count = prediction_count_value as usize;
    let prediction_width = prediction_width_value as usize;
    if position + prediction_count * prediction_width != input_length {
        return -1;
    }
    let mut prediction_features = [0i64; 64];
    for index in 0..prediction_count * prediction_width {
        let count = values[position];
        position += 1;
        if !(0..=100).contains(&count) {
            return -1;
        }
        prediction_features[index / prediction_width * 8 + index % prediction_width] = count;
    }

    let mut predictions = [0i64; 8];
    for row in 0..prediction_count {
        let mut best_score = f64::NEG_INFINITY;
        let mut second_score = f64::NEG_INFINITY;
        let mut best_label = -1i64;
        for label in 0..8 {
            if class_counts[label] == 0 {
                continue;
            }
            let mut score = ((class_counts[label] as f64) / (training_rows as f64)).ln();
            let denominator = class_totals[label] + feature_width as f64;
            for column in 0..feature_width {
                let likelihood = (feature_sums[label * 8 + column] + 1.0) / denominator;
                score += (prediction_features[row * 8 + column] as f64) * likelihood.ln();
            }
            if score > best_score {
                second_score = best_score;
                best_score = score;
                best_label = label as i64;
            } else if score > second_score {
                second_score = score;
            }
        }
        if best_label < 0 || (second_score != f64::NEG_INFINITY && best_score - second_score < 1e-8) {
            return -1;
        }
        predictions[row] = best_label;
    }

    let output_words = prediction_count + 1;
    let output_bytes = output_words * 8;
    if output.is_null() || output_capacity < output_bytes || output_bytes > 72 {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    output_slice[..8].copy_from_slice(&prediction_count_value.to_le_bytes());
    for index in 0..prediction_count {
        output_slice[(index + 1) * 8..(index + 2) * 8].copy_from_slice(&predictions[index].to_le_bytes());
    }
    output_bytes as i64
}
