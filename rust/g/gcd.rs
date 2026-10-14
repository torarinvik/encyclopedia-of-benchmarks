/// Portable iterative Euclidean GCD; workload values fit signed 64-bit.
#[no_mangle]
pub extern "C" fn gcd(mut left: u64, mut right: u64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left as i64
}
