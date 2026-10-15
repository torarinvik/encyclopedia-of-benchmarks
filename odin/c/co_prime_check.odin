package co_prime_check

// Return whether two nonnegative int32 values have greatest common divisor one.
@(export)
co_prime_check :: proc "c" (first, second: u64) -> i64 {
    if first > 2_147_483_647 || second > 2_147_483_647 do return -1
    left := first
    right := second
    for right != 0 {
        remainder := left % right
        left = right
        right = remainder
    }
    if left == 1 do return 1
    return 0
}
