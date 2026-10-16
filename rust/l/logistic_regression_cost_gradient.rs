const MAX_SAMPLES: usize = 64;
const MAX_FEATURES: usize = 8;
const Q_SCALE: f64 = 1_000_000.0;

fn put_f64(output: *mut u8, offset: usize, value: f64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() {
        unsafe { *output.add(offset + index) = *byte; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn logistic_regression_cost_gradient(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let m_value = *input;
    let d_value = *input.add(1);
    if m_value < 1 || m_value > MAX_SAMPLES as i64 || d_value < 1 || d_value > MAX_FEATURES as i64 { return -1; }
    let m = m_value as usize;
    let d = d_value as usize;
    let features_offset = 2;
    let theta_offset = features_offset + m * d;
    let labels_offset = theta_offset + d;
    if length != labels_offset + m { return -1; }
    for index in 0..m * d {
        let value = *input.add(features_offset + index);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
    }
    for feature in 0..d {
        let value = *input.add(theta_offset + feature);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
    }
    for sample in 0..m {
        let label = *input.add(labels_offset + sample);
        if label != 0 && label != 1 { return -1; }
    }
    let required = (d + 1) * 8;
    if output.is_null() || capacity < required { return -2; }

    let mut loss = 0.0;
    let mut gradient = [0.0; MAX_FEATURES];
    for sample in 0..m {
        let mut score = 0.0;
        for feature in 0..d {
            let x = *input.add(features_offset + sample * d + feature) as f64 / Q_SCALE;
            let theta = *input.add(theta_offset + feature) as f64 / Q_SCALE;
            score += x * theta;
        }
        let probability = 1.0 / (1.0 + (-score).exp());
        let label = *input.add(labels_offset + sample) as f64;
        loss += -label * probability.ln() - (1.0 - label) * (1.0 - probability).ln();
        let error = probability - label;
        for feature in 0..d {
            let x = *input.add(features_offset + sample * d + feature) as f64 / Q_SCALE;
            gradient[feature] += error * x;
        }
    }
    put_f64(output, 0, loss / m as f64);
    for feature in 0..d {
        put_f64(output, (feature + 1) * 8, gradient[feature] / m as f64);
    }
    required as i64
}
