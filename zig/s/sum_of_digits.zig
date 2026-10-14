/// Iteratively add the decimal digits of a signed 32-bit integer's magnitude.
export fn sum_of_digits(input: i64) i64 {
    if (input < -2147483648 or input > 2147483647) return -1;
    var remaining: u64 = @intCast(if (input < 0) -input else input);
    var total: i64 = 0;
    while (remaining != 0) {
        total += @intCast(remaining % 10);
        remaining /= 10;
    }
    return total;
}
