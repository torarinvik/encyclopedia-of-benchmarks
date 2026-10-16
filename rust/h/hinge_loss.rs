const MAX_COUNT: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_COUNT;
const PREDICTION_SCALE: f64 = 1_000_000.0;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn hinge_loss(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let values = std::slice::from_raw_parts(values, length);
    let count_value = values[0];
    if count_value < 1 || count_value > MAX_COUNT as i64 {
        return INVALID_RESULT;
    }
    let count = count_value as usize;
    if length != 1 + 2 * count {
        return INVALID_RESULT;
    }

    let labels = &values[1..1 + count];
    let predictions_scaled = &values[1 + count..];
    let mut total = 0.0f64;
    for (&label, &score_scaled) in labels.iter().zip(predictions_scaled.iter()) {
        if (label != -1 && label != 1) || !(-1_000_000..=1_000_000).contains(&score_scaled) {
            return INVALID_RESULT;
        }
        let prediction = score_scaled as f64 / PREDICTION_SCALE;
        let loss = 1.0 - label as f64 * prediction;
        if loss > 0.0 {
            total += loss;
        }
    }
    total / count as f64
}
