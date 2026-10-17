const MAX_INPUT_LENGTH: usize = 2051;
#[no_mangle]
pub unsafe extern "C" fn logistic_regression_predict(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let (rows, features) = (input[0], input[1]);
    if !(1..=63).contains(&rows) || !(1..=32).contains(&features) ||
        length != 2 + (rows * features + features) as usize { return -1; }
    let theta_offset = 2 + (rows * features) as usize;
    for &value in &input[2..] { if !(-1000..=1000).contains(&value) { return -1; } }
    let mut mask = 0u64;
    for row in 0..rows as usize {
        let mut score = 0i64;
        for feature in 0..features as usize { score += input[2 + row * features as usize + feature] * input[theta_offset + feature]; }
        if score >= 0 { mask |= 1u64 << row; }
    }
    mask as i64
}
