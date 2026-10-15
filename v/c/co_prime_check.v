module co_prime_check

// Return whether two nonnegative int32 values have greatest common divisor one.
@[export: 'co_prime_check']
pub fn co_prime_check(first u64, second u64) i64 {
    if first > u64(2147483647) || second > u64(2147483647) { return -1 }
    mut left := first
    mut right := second
    for right != 0 {
        remainder := left % right
        left = right
        right = remainder
    }
    if left == 1 { return 1 }
    return 0
}
