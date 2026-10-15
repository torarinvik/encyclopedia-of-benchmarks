/// Recursive subtraction-based Euclidean GCD on a bounded positive domain.
fn gcd_recursive_euclidean_step(left: u64, right: u64) -> i64 {
    if left == right {
        return left as i64;
    }
    if left > right {
        return gcd_recursive_euclidean_step(left - right, right);
    }
    gcd_recursive_euclidean_step(left, right - left)
}

#[no_mangle]
pub extern "C" fn gcd_recursive_euclidean(left: u64, right: u64) -> i64 {
    if left == 0 || right == 0 || left > 128 || right > 128 {
        return -1;
    }
    gcd_recursive_euclidean_step(left, right)
}
