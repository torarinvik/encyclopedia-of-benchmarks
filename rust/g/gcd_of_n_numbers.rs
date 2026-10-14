/// Fold positive signed 32-bit values with Euclid's GCD algorithm.
#[no_mangle]
pub unsafe extern "C" fn gcd_of_n_numbers(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > 64 { return -1; }
    let mut result = *values;
    if !(1..=i32::MAX as i64).contains(&result) { return -1; }
    for index in 1..length {
        let value = *values.add(index);
        if !(1..=i32::MAX as i64).contains(&value) { return -1; }
        if result != 1 {
            let mut left = result;
            let mut right = value;
            while right != 0 {
                let remainder = left % right;
                left = right;
                right = remainder;
            }
            result = left;
        }
    }
    result
}
