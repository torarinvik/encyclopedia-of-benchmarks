export fn bitwise_gcd(left_value: u64, right_value: u64) i64 {
    if (left_value == 0) return @intCast(right_value);
    if (right_value == 0) return @intCast(left_value);

    var left = left_value;
    var right = right_value;
    const common_twos = @ctz(left | right);
    left >>= @ctz(left);
    while (right != 0) {
        right >>= @ctz(right);
        if (left > right) {
            const temp = left;
            left = right;
            right = temp;
        }
        right -= left;
    }
    return @intCast(left << common_twos);
}
