/// Return the exact zero-based Catalan number through the signed 64-bit range.
fn gcd_i64(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

export fn catalan_number(n: i64) i64 {
    if (n < 0 or n > 35) return -1;
    var value: i64 = 1;
    var index: i64 = 1;
    while (index <= n) : (index += 1) {
        var numerator: i64 = 4 * index - 2;
        var denominator: i64 = index + 1;
        const common = gcd_i64(numerator, denominator);
        numerator = @divTrunc(numerator, common);
        denominator = @divTrunc(denominator, common);
        value = @divTrunc(value, denominator) * numerator;
    }
    return value;
}
