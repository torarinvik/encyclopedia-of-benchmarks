const INVALID: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn mean_bias_deviation_percent(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 1 || length > 131 {
        return INVALID;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=64).contains(&values[0]) {
        return INVALID;
    }
    let count = values[0] as usize;
    if length != 1 + 2 * count {
        return INVALID;
    }
    let mut difference_sum = 0i64;
    let mut actual_sum = 0i64;
    for index in 0..count {
        let prediction = values[1 + index];
        let actual = values[1 + count + index];
        if !(-1000..=1000).contains(&prediction) || !(-1000..=1000).contains(&actual) {
            return INVALID;
        }
        difference_sum += prediction - actual;
        actual_sum += actual;
    }
    if actual_sum == 0 {
        return INVALID;
    }
    let numerator = difference_sum as f64 / count as f64;
    let denominator = actual_sum as f64 / count as f64;
    numerator / denominator * 100.0
}
