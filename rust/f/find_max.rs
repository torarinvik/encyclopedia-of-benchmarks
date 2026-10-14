/// Return the largest signed value in a nonempty array.
#[no_mangle]
pub unsafe extern "C" fn find_max(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > 512 { return -1; }
    let mut result = *values;
    for index in 1..length {
        let value = *values.add(index);
        if value > result { result = value; }
    }
    result
}
