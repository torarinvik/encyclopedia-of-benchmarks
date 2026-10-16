const SCALE: i64 = 1_000_000;
const MAX_PAIRS: i64 = 64;
const MAX_PARSED_PAIRS: i64 = 65;
const MAX_SAMPLE: i64 = 1_000_000_000;
const MAX_DELTA: i64 = 1_000_000_000;
const MAX_INPUT_LENGTH: usize = 133;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn huber_loss(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let delta_value = *values;
    let true_count = *values.add(1);
    let pred_count = *values.add(2);
    if delta_value < 0 || delta_value > MAX_DELTA ||
        true_count < 0 || true_count > MAX_PARSED_PAIRS ||
        pred_count < 0 || pred_count > MAX_PARSED_PAIRS { return INVALID_RESULT; }
    if length != (3 + true_count + pred_count) as usize || true_count != pred_count ||
        pred_count == 0 || true_count > MAX_PAIRS { return INVALID_RESULT; }

    let count = true_count as usize;
    for index in 0..count * 2 {
        let value = *values.add(3 + index);
        if value < -MAX_SAMPLE || value > MAX_SAMPLE { return INVALID_RESULT; }
    }
    let delta = delta_value as f64 / SCALE as f64;
    let mut total_loss = 0.0;
    for index in 0..count {
        let true_value = *values.add(3 + index) as f64 / SCALE as f64;
        let predicted_value = *values.add(3 + count + index) as f64 / SCALE as f64;
        let residual = (true_value - predicted_value).abs();
        if residual <= delta {
            total_loss += 0.5 * (residual * residual);
        } else {
            total_loss += delta * residual - 0.5 * (delta * delta);
        }
    }
    total_loss / count as f64
}
