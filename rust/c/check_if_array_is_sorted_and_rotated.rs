/// Check whether the values are a rotation of a nondecreasing array.
#[no_mangle]
pub extern "C" fn check_if_array_is_sorted_and_rotated(values: *const i64, length: usize) -> i64 {
    if length > 256 {
        return -1;
    }
    if length == 0 {
        return 1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|value| i32::try_from(*value).is_err()) {
        return -1;
    }
    let mut descents = 0;
    for index in 0..length {
        if values[index] > values[(index + 1) % length] {
            descents += 1;
            if descents > 1 {
                return 0;
            }
        }
    }
    1
}
