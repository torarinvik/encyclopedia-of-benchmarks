const MAX_LENGTH: usize = 62;
const INVALID_RESULT: i64 = -1;

fn type7_quantile(sorted: &[i64], probability: f64) -> f64 {
    let count = sorted.len();
    let h = (count - 1) as f64 * probability + 1.0;
    let order = h as usize;
    let fraction = h - order as f64;
    let lower = order - 1;
    if fraction == 0.0 || lower + 1 >= count { return sorted[lower] as f64; }
    (1.0 - fraction) * sorted[lower] as f64 + fraction * sorted[lower + 1] as f64
}

#[no_mangle]
pub extern "C" fn iqr_outlier_indices(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_LENGTH { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return INVALID_RESULT; }
    let mut sorted = [0_i64; MAX_LENGTH];
    for (i, &value) in input.iter().enumerate() {
        let mut position = i;
        while position > 0 && sorted[position - 1] > value {
            sorted[position] = sorted[position - 1];
            position -= 1;
        }
        sorted[position] = value;
    }
    let sorted = &sorted[..length];
    let q1 = type7_quantile(sorted, 0.25);
    let q3 = type7_quantile(sorted, 0.75);
    let iqr = q3 - q1;
    let lower_bound = q1 - 1.5 * iqr;
    let upper_bound = q3 + 1.5 * iqr;
    let mut mask = 0_i64;
    for (i, &value) in input.iter().enumerate() {
        if (value as f64) < lower_bound || (value as f64) > upper_bound { mask |= 1_i64 << i; }
    }
    mask
}
