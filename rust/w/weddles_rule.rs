const MAX_PANELS: i64 = 64;
const MAX_STEP_NANOUNITS: i64 = 1_000_000_000;
const MAX_SAMPLE_MICRO: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn weddles_rule(values: *const i64, length: usize) -> f64 {
    if values.is_null() || !(9..=387).contains(&length) { return INVALID_RESULT; }
    let panels = *values;
    let step_nanounits = *values.add(1);
    if !(1..=MAX_PANELS).contains(&panels) || length != (6 * panels + 3) as usize ||
        !(-MAX_STEP_NANOUNITS..=MAX_STEP_NANOUNITS).contains(&step_nanounits) {
        return INVALID_RESULT;
    }

    let sample_count = (6 * panels + 1) as usize;
    let mut weighted_sum = 0.0;
    for index in 1..sample_count - 1 {
        let sample_micro = *values.add(index + 2);
        if !(-MAX_SAMPLE_MICRO..=MAX_SAMPLE_MICRO).contains(&sample_micro) { return INVALID_RESULT; }
        let weight = if index % 2 == 0 && index % 3 != 0 { 1 }
            else if index % 2 != 0 && index % 3 != 0 { 5 }
            else if index % 6 == 0 { 2 }
            else { 6 };
        weighted_sum += (weight as f64) * (sample_micro as f64 / 1_000_000.0);
    }
    let first_micro = *values.add(2);
    let last_micro = *values.add(sample_count + 1);
    if !(-MAX_SAMPLE_MICRO..=MAX_SAMPLE_MICRO).contains(&first_micro) ||
        !(-MAX_SAMPLE_MICRO..=MAX_SAMPLE_MICRO).contains(&last_micro) {
        return INVALID_RESULT;
    }
    let step_size = step_nanounits as f64 / 1_000_000_000.0;
    0.3 * step_size * (weighted_sum + first_micro as f64 / 1_000_000.0 + last_micro as f64 / 1_000_000.0)
}
