module kelly_criterion

const scale = i64(1_000_000)
const min_probability_micro = i64(1)
const max_probability_micro = i64(999_999)
const min_ratio_micro = i64(1_000)
const max_ratio_micro = i64(100_000_000)
const max_input_length = usize(3)
const invalid_result = -1.0e300

@[export: 'kelly_criterion']
pub fn kelly_criterion(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 2 || length > max_input_length { return invalid_result }
    probability_micro, ratio_micro := unsafe { values[0] }, unsafe { values[1] }
    if probability_micro < min_probability_micro || probability_micro > max_probability_micro || ratio_micro < min_ratio_micro || ratio_micro > max_ratio_micro { return invalid_result }
    win_probability := f64(probability_micro) / f64(scale)
    win_loss_ratio := f64(ratio_micro) / f64(scale)
    loss_probability := 1.0 - win_probability
    return (win_probability * win_loss_ratio - loss_probability) / win_loss_ratio
}
