/// Portable iterative Euclidean GCD; inputs are in the nonnegative i64 range.
export fn gcd(left_value: u64, right_value: u64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = left % right;
        left = right;
        right = remainder;
    }
    return @intCast(left);
}
