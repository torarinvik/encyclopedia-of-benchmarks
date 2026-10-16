const SCALE: i64 = 1_000_000;
const MIN_PROBABILITY_MICRO: i64 = 1;
const MAX_PROBABILITY_MICRO: i64 = 999_999;
const MIN_RATIO_MICRO: i64 = 1_000;
const MAX_RATIO_MICRO: i64 = 100_000_000;
const MAX_INPUT_LENGTH: usize = 3;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn kelly_criterion(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let probability_micro = *values;
    let ratio_micro = *values.add(1);
    if probability_micro < MIN_PROBABILITY_MICRO || probability_micro > MAX_PROBABILITY_MICRO
            || ratio_micro < MIN_RATIO_MICRO || ratio_micro > MAX_RATIO_MICRO { return INVALID_RESULT; }
    let win_probability = probability_micro as f64 / SCALE as f64;
    let win_loss_ratio = ratio_micro as f64 / SCALE as f64;
    let loss_probability = 1.0 - win_probability;
    (win_probability * win_loss_ratio - loss_probability) / win_loss_ratio
}
