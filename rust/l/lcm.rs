/// Portable LCM with overflow checked after dividing by the GCD.
#[no_mangle]
pub extern "C" fn lcm(left: u64, right: u64) -> i64 {
    if left == 0 || right == 0 { return 0; }
    let (mut a, mut b) = (left, right);
    while b != 0 {
        let remainder = a % b;
        a = b;
        b = remainder;
    }
    let reduced = left / a;
    let max_result = i64::MAX as u64;
    if reduced > max_result / right { return -1; }
    (reduced * right) as i64
}
