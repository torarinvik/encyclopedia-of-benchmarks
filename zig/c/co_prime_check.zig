/// Return whether two nonnegative int32 values have greatest common divisor one.
export fn co_prime_check(first: u64, second: u64) i64 {
    if (first > 2147483647 or second > 2147483647) return -1;
    var left = first;
    var right = second;
    while (right != 0) {
        const remainder = left % right;
        left = right;
        right = remainder;
    }
    return if (left == 1) 1 else 0;
}
