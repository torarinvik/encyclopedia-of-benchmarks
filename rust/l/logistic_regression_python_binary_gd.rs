const MAX_SAMPLES: usize = 32;
const MAX_FEATURES: usize = 8;
const Q_SCALE: f64 = 1_000_000.0;

fn put_f64(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn logistic_regression_python_binary_gd(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let mv = values[0];
    let dv = values[1];
    let epochs_v = values[2];
    let alpha_q = values[3];
    if mv < 1 || mv > MAX_SAMPLES as i64 || dv < 1 || dv > MAX_FEATURES as i64
        || epochs_v < 0 || epochs_v > 128 || alpha_q < 1 || alpha_q > 100_000 {
        return -1;
    }
    let m = mv as usize;
    let d = dv as usize;
    let epochs = epochs_v as usize;
    if length != 4 + m * d + m {
        return -1;
    }
    let labels_offset = 4 + m * d;
    if values[4..labels_offset].iter().any(|x| *x < -1_000_000 || *x > 1_000_000)
        || values[labels_offset..].iter().any(|label| *label != 0 && *label != 1) {
        return -1;
    }
    let required = d * 8;
    if output.is_null() || capacity < required {
        return -2;
    }

    let mut theta = [0.0f64; MAX_FEATURES];
    let mut next_theta = [0.0f64; MAX_FEATURES];
    let mut errors = [0.0f64; MAX_SAMPLES];
    let alpha = alpha_q as f64 / Q_SCALE;
    for _ in 0..epochs {
        for sample in 0..m {
            let mut score = 0.0;
            for feature in 0..d {
                let x = values[4 + sample * d + feature] as f64 / Q_SCALE;
                score += x * theta[feature];
            }
            let prediction = 1.0 / (1.0 + (-score).exp());
            errors[sample] = prediction - values[labels_offset + sample] as f64;
        }
        for feature in 0..d {
            let mut gradient = 0.0;
            for sample in 0..m {
                let x = values[4 + sample * d + feature] as f64 / Q_SCALE;
                gradient += x * errors[sample];
            }
            gradient /= m as f64;
            next_theta[feature] = theta[feature] - alpha * gradient;
        }
        for feature in 0..d {
            theta[feature] = next_theta[feature];
        }
    }
    let out = std::slice::from_raw_parts_mut(output, required);
    for feature in 0..d {
        put_f64(out, feature * 8, theta[feature]);
    }
    required as i64
}
