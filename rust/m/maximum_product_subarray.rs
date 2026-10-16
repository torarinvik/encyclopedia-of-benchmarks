/// Maximum product of a nonempty contiguous subarray.
const MAX_INPUT_LENGTH: usize = 9;

#[no_mangle]
pub unsafe extern "C" fn maximum_product_subarray(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_INPUT_LENGTH { return i64::MIN; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| !(-10..=10).contains(&value)) { return i64::MIN; }

    let mut current_max = values[0];
    let mut current_min = values[0];
    let mut best = values[0];
    for &value in &values[1..] {
        let prior_max = current_max;
        let prior_min = current_min;
        let from_max = prior_max * value;
        let from_min = prior_min * value;
        current_max = value.max(from_max).max(from_min);
        current_min = value.min(from_max).min(from_min);
        best = best.max(current_max);
    }
    best
}
