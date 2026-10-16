const MAX_LENGTH: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn maximum_subarray_allow_empty(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length > 0 && values.is_null()) { return -1; }
    let input: &[i64] = if length == 0 { &[] } else { std::slice::from_raw_parts(values, length) };
    if input.iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) {
        return -1;
    }
    let mut current = 0i64;
    let mut best = 0i64;
    for &value in input {
        current += value;
        if current < 0 { current = 0; }
        if current > best { best = current; }
    }
    best
}
