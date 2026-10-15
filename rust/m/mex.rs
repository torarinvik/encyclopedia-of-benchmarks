const MAX_VALUES: usize = 100_000;

/// Return the smallest absent nonnegative value after sorting a local copy.
#[no_mangle]
pub unsafe extern "C" fn mex(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_VALUES + 1 { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    let count_value = packed[0];
    if count_value < 0 || count_value > MAX_VALUES as i64 || length != count_value as usize + 1 {
        return -1;
    }
    let count = count_value as usize;
    let mut values = [0i64; MAX_VALUES];
    for index in 0..count {
        let value = packed[index + 1];
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        values[index] = value;
    }
    values[..count].sort_unstable();
    let mut candidate = 0i64;
    for &value in &values[..count] {
        if value == candidate { candidate += 1; }
    }
    candidate
}
