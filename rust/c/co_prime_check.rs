/// Return whether two nonnegative int32 values have greatest common divisor one.
#[no_mangle]
pub extern "C" fn co_prime_check(first: u64, second: u64) -> i64 {
    if first > i32::MAX as u64 || second > i32::MAX as u64 { return -1; }
    let mut left = first;
    let mut right = second;
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    if left == 1 { 1 } else { 0 }
}
