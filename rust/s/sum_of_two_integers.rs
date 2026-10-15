/// Add two signed i32 operands with XOR and shifted carry in a 64-bit word.
fn bitwise_add(a: i64, b: i64) -> i64 {
    let mut left = a as u64;
    let mut right = b as u64;
    while right != 0 {
        let partial = left ^ right;
        right = (left & right) << 1;
        left = partial;
    }
    left as i64
}

#[no_mangle]
pub extern "C" fn sum_of_two_integers(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < i32::MIN as i64 || values[0] > i32::MAX as i64 ||
        values[1] < i32::MIN as i64 || values[1] > i32::MAX as i64 { return -1; }
    bitwise_add(values[0], values[1])
}
