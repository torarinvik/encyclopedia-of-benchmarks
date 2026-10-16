const MAX_LENGTH: usize = 1024;
const MAX_ABS_VALUE: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn maximum_subarray_int32(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|&value| value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) {
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
