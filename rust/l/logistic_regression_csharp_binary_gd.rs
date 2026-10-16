const MAX_SAMPLES: usize = 32;
const MAX_FEATURES: usize = 8;
const Q_SCALE: f64 = 1_000_000.0;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn logistic_regression_csharp_binary_gd(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 4 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let mv = values[0];
    let dv = values[1];
    let epochs_v = values[2];
    let rate_q = values[3];
    if mv < 1 || mv > MAX_SAMPLES as i64 || dv < 1 || dv > MAX_FEATURES as i64
        || epochs_v < 0 || epochs_v > 128 || rate_q < 1 || rate_q > 100_000 { return INVALID_RESULT; }
    let m = mv as usize;
    let d = dv as usize;
    let epochs = epochs_v as usize;
    let labels_offset = 4 + m * d;
    let query_offset = labels_offset + m;
    if length != query_offset + d { return INVALID_RESULT; }
    if values[4..labels_offset].iter().any(|x| *x < -1_000_000 || *x > 1_000_000)
        || values[labels_offset..query_offset].iter().any(|label| *label != 0 && *label != 1)
        || values[query_offset..].iter().any(|x| *x < -1_000_000 || *x > 1_000_000) {
        return INVALID_RESULT;
    }

    let mut weights = [0.0f64; MAX_FEATURES];
    let mut gradient = [0.0f64; MAX_FEATURES];
    let mut bias = 0.0;
    let learning_rate = rate_q as f64 / Q_SCALE;
    for _ in 0..epochs {
        for feature in 0..d { gradient[feature] = 0.0; }
        let mut bias_gradient = 0.0;
        for sample in 0..m {
            let mut dot = 0.0;
            for feature in 0..d {
                let x = values[4 + sample * d + feature] as f64 / Q_SCALE;
                dot += x * weights[feature];
            }
            let linear = dot + bias;
            let prediction = 1.0 / (1.0 + (-linear).exp());
            let error = prediction - values[labels_offset + sample] as f64;
            for feature in 0..d {
                let x = values[4 + sample * d + feature] as f64 / Q_SCALE;
                gradient[feature] += error * x;
            }
            bias_gradient += error;
        }
        for feature in 0..d {
            weights[feature] -= learning_rate * gradient[feature] / m as f64;
        }
        bias -= learning_rate * bias_gradient / m as f64;
    }
    let mut query_dot = 0.0;
    for feature in 0..d {
        let x = values[query_offset + feature] as f64 / Q_SCALE;
        query_dot += x * weights[feature];
    }
    let query_linear = query_dot + bias;
    1.0 / (1.0 + (-query_linear).exp())
}
