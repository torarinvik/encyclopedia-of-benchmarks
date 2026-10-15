/// Return the maximum sum among windows of exactly k consecutive values.
#[no_mangle]
pub extern "C" fn max_sum_sliding_window(values: *const i64, length: usize) -> i64 {
    const INVALID: i64 = i64::MIN;
    if values.is_null() || !(3..=100002).contains(&length) {
        return INVALID;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (n_value, k_value) = (values[0], values[1]);
    if !(1..=100000).contains(&n_value) || k_value < 1 || k_value > n_value
        || length != n_value as usize + 2
    {
        return INVALID;
    }
    let (n, k) = (n_value as usize, k_value as usize);
    let mut current_sum = 0i64;
    for i in 0..n {
        let value = values[i + 2];
        if !(-1_000_000_000..=1_000_000_000).contains(&value) {
            return INVALID;
        }
        if i < k {
            current_sum += value;
        }
    }
    let mut maximum_sum = current_sum;
    for i in 0..n - k {
        current_sum = current_sum - values[i + 2] + values[i + k + 2];
        maximum_sum = maximum_sum.max(current_sum);
    }
    maximum_sum
}
