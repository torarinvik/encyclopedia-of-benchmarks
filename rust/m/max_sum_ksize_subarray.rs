/// Maximum sum of a fixed-size window; the final packed value is k.
#[no_mangle]
pub unsafe extern "C" fn max_sum_ksize_subarray(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > 64 || values.is_null() { return -1; }
    let packed = std::slice::from_raw_parts(values, length);
    let array_length = length - 1;
    let k_value = packed[array_length];
    if k_value < 0 || k_value > array_length as i64 { return -1; }
    if packed[..array_length].iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) {
        return -1;
    }
    if k_value == 0 { return 0; }

    let k = k_value as usize;
    let mut window_sum: i64 = packed[..k].iter().sum();
    let mut maximum_sum = window_sum;
    for index in k..array_length {
        window_sum += packed[index] - packed[index - k];
        maximum_sum = maximum_sum.max(window_sum);
    }
    maximum_sum
}
