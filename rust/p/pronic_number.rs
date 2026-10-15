/// Check whether n is the product of two consecutive nonnegative integers.
#[no_mangle]
pub extern "C" fn pronic_number(n: i64) -> i64 {
    if !(0..=i32::MAX as i64).contains(&n) {
        return -1;
    }
    let root = (n as f64).sqrt() as i64;
    if root * (root + 1) == n { 1 } else { 0 }
}
