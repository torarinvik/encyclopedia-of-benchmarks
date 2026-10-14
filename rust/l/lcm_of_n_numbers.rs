/// Fold a list of nonnegative values with overflow-safe Euclidean LCM.
#[no_mangle]
pub extern "C" fn lcm_of_n_numbers(values: *const i64, length: usize) -> i64 {
    if length == 0 { return 1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| value == 0) { return 0; }
    let mut accumulator = 1u64;
    let maximum = i64::MAX as u64;
    for &item in values {
        let value = item as u64;
        let (mut left, mut right) = (accumulator, value);
        while right != 0 {
            let remainder = left % right;
            left = right;
            right = remainder;
        }
        let reduced = accumulator / left;
        if reduced > maximum / value { return -1; }
        accumulator = reduced * value;
    }
    accumulator as i64
}
