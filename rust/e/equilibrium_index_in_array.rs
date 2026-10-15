/// Return the first index with equal left and right sums.
const MAX_LENGTH: usize = 1024;
const MIN_I32: i64 = i32::MIN as i64;
const MAX_I32: i64 = i32::MAX as i64;

#[no_mangle]
pub extern "C" fn equilibrium_index_in_array(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 || length > MAX_LENGTH + 1 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let n = values[0];
    if n < 0 || n > MAX_LENGTH as i64 || length != n as usize + 1 { return -2; }
    let mut total = 0i64;
    for &value in &values[1..] {
        if !(MIN_I32..=MAX_I32).contains(&value) { return -2; }
        total += value;
    }
    let mut left = 0i64;
    for index in 0..n as usize {
        let value = values[index + 1];
        total -= value;
        if left == total { return index as i64; }
        left += value;
    }
    -1
}
