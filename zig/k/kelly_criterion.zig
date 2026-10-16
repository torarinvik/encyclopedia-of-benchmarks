const SCALE: i64 = 1_000_000;
const MIN_PROBABILITY_MICRO: i64 = 1;
const MAX_PROBABILITY_MICRO: i64 = 999_999;
const MIN_RATIO_MICRO: i64 = 1_000;
const MAX_RATIO_MICRO: i64 = 100_000_000;
const MAX_INPUT_LENGTH: usize = 3;
const INVALID_RESULT: f64 = -1.0e300;

export fn kelly_criterion(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const probability_micro = values[0];
    const ratio_micro = values[1];
    if (probability_micro < MIN_PROBABILITY_MICRO or probability_micro > MAX_PROBABILITY_MICRO
        or ratio_micro < MIN_RATIO_MICRO or ratio_micro > MAX_RATIO_MICRO) return INVALID_RESULT;
    const win_probability = @as(f64, @floatFromInt(probability_micro)) / @as(f64, @floatFromInt(SCALE));
    const win_loss_ratio = @as(f64, @floatFromInt(ratio_micro)) / @as(f64, @floatFromInt(SCALE));
    const loss_probability = 1.0 - win_probability;
    return (win_probability * win_loss_ratio - loss_probability) / win_loss_ratio;
}
