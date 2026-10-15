/// Kadane's maximum nonempty contiguous-subarray sum.
#[no_mangle]
pub extern "C" fn maximum_subarray(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > 1024 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) {
        return -1;
    }
    let mut current = values[0];
    let mut best = current;
    for &value in &values[1..] {
        current = if current > 0 { current + value } else { value };
        if current > best { best = current; }
    }
    best
}
