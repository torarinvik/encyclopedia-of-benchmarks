/// Return the minimum sum among fixed-size windows, preserving Java's k==0 and k>n cases.
#[no_mangle]
pub extern "C" fn min_sum_ksize_subarray(values: *const i64, length: usize) -> i64 {
    const INVALID: i64 = i64::MIN;
    if values.is_null() || !(2..=100002).contains(&length) {
        return INVALID;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (n_value, k_value) = (values[0], values[1]);
    if !(0..=100000).contains(&n_value) || !(0..=100000).contains(&k_value)
        || length != n_value as usize + 2
    {
        return INVALID;
    }
    let (n, k) = (n_value as usize, k_value as usize);
    if values[2..].iter().any(|&x| !(-10000..=10000).contains(&x)) {
        return INVALID;
    }
    if k > n {
        return -1;
    }
    let mut window_sum = 0i64;
    for i in 0..k {
        window_sum += values[i + 2];
    }
    let mut minimum_sum = window_sum;
    for i in k..n {
        window_sum += values[i + 2] - values[i - k + 2];
        minimum_sum = minimum_sum.min(window_sum);
    }
    minimum_sum
}
