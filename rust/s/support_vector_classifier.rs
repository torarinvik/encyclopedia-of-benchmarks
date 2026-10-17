const MAX_N: usize = 8;
const MAX_D: usize = 4;
const MAX_Q: usize = 16;
const MAX_INPUT_VALUES: usize = 108;

fn kernel_value(left: &[f64; MAX_D], right: &[f64; MAX_D], dimension: usize, kind: i64) -> f64 {
    if kind == 0 {
        let mut total = 0.0;
        for index in 0..dimension { total += left[index] * right[index]; }
        return total;
    }
    let mut norm_squared = 0.0;
    for index in 0..dimension {
        let difference = left[index] - right[index];
        norm_squared += difference * difference;
    }
    (-norm_squared).exp()
}

fn fit_predict(
    labels: &[f64; MAX_N],
    training: &[[f64; MAX_D]; MAX_N],
    testing: &[[f64; MAX_D]; MAX_Q],
    n: usize,
    dimension: usize,
    query_count: usize,
    kind: i64,
) -> i64 {
    let mut kernel_matrix = [[0.0; MAX_N]; MAX_N];
    for i in 0..n {
        for j in 0..n {
            kernel_matrix[i][j] = kernel_value(&training[i], &training[j], dimension, kind);
        }
    }

    let mut optimum = [0.0; MAX_N];
    for i in 0..n { optimum[i] = 0.5; }
    for iteration in 0..5000 {
        let mut gradient = [0.0; MAX_N];
        for i in 0..n {
            let mut total = 0.0;
            for j in 0..n { total += optimum[j] * labels[j] * kernel_matrix[i][j]; }
            gradient[i] = labels[i] * total - 1.0;
        }
        let old_optimum = optimum;
        let learning_rate = 0.1 / (1.0 + iteration as f64 / 1000.0);
        for i in 0..n {
            let updated = optimum[i] - learning_rate * gradient[i];
            optimum[i] = updated.max(0.0).min(1.0);
        }

        let mut sum_label_lambda = 0.0;
        for i in 0..n { sum_label_lambda += optimum[i] * labels[i]; }
        let mut correction = sum_label_lambda / n as f64;
        for _ in 0..10 {
            for i in 0..n {
                let delta = correction * labels[i];
                optimum[i] = (optimum[i] - delta).max(0.0).min(1.0);
            }
            sum_label_lambda = 0.0;
            for i in 0..n { sum_label_lambda += optimum[i] * labels[i]; }
            correction = sum_label_lambda / n as f64;
            if sum_label_lambda.abs() < 1e-10 { break; }
        }
        let mut difference_squared = 0.0;
        for i in 0..n {
            let difference = optimum[i] - old_optimum[i];
            difference_squared += difference * difference;
        }
        if difference_squared.sqrt() < 1e-8 { break; }
    }

    let mut offset_total = 0.0;
    let mut offset_count = 0usize;
    for i in 0..n {
        if optimum[i] > 1e-5 && optimum[i] < 1.0 - 1e-5 {
            let mut kernel_sum = 0.0;
            for j in 0..n {
                kernel_sum += optimum[j] * labels[j] * kernel_value(&training[j], &training[i], dimension, kind);
            }
            offset_total += labels[i] - kernel_sum;
            offset_count += 1;
        }
    }
    if offset_count == 0 {
        for i in 0..n {
            let mut kernel_sum = 0.0;
            for j in 0..n {
                kernel_sum += optimum[j] * labels[j] * kernel_value(&training[j], &training[i], dimension, kind);
            }
            offset_total += labels[i] - kernel_sum;
        }
        offset_total /= n as f64;
    } else {
        offset_total /= offset_count as f64;
    }

    let mut mask = 0i64;
    for i in 0..query_count {
        let mut total = 0.0;
        for j in 0..n {
            total += optimum[j] * labels[j] * kernel_value(&training[j], &testing[i], dimension, kind);
        }
        if total + offset_total >= 0.0 { mask |= 1i64 << i; }
    }
    mask
}

#[no_mangle]
pub unsafe extern "C" fn support_vector_classifier(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_VALUES + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let dimension_value = values[1];
    let kind = values[2];
    let query_value = values[3];
    if !(2..=MAX_N as i64).contains(&n_value) || !(1..=MAX_D as i64).contains(&dimension_value)
        || !(0..=1).contains(&kind) || !(1..=MAX_Q as i64).contains(&query_value) { return -1; }
    let n = n_value as usize;
    let dimension = dimension_value as usize;
    let query_count = query_value as usize;
    let expected_length = 4 + n + n * dimension + query_count * dimension;
    if length != expected_length { return -1; }

    let mut labels = [0.0; MAX_N];
    let mut saw_negative = false;
    let mut saw_positive = false;
    for i in 0..n {
        let label = values[4 + i];
        if label != -1 && label != 1 { return -1; }
        labels[i] = label as f64;
        if label < 0 { saw_negative = true; } else { saw_positive = true; }
    }
    if !saw_negative || !saw_positive { return -1; }

    let mut training = [[0.0; MAX_D]; MAX_N];
    let mut testing = [[0.0; MAX_D]; MAX_Q];
    let training_start = 4 + n;
    for i in 0..n {
        for j in 0..dimension {
            let value = values[training_start + i * dimension + j];
            if !(-4..=4).contains(&value) { return -1; }
            training[i][j] = value as f64;
        }
    }
    let testing_start = training_start + n * dimension;
    for i in 0..query_count {
        for j in 0..dimension {
            let value = values[testing_start + i * dimension + j];
            if !(-4..=4).contains(&value) { return -1; }
            testing[i][j] = value as f64;
        }
    }
    fit_predict(&labels, &training, &testing, n, dimension, query_count, kind)
}
