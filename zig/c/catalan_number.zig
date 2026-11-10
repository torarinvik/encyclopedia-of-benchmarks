/// Return the exact zero-based Catalan number through the signed 64-bit range.
export fn catalan_number(n: i64) i64 {
    if (n < 0 or n > 35) return -1;
    var value: i64 = 1;
    var index: i64 = 1;
    while (index <= n) : (index += 1) {
        var numerator: i64 = 4 * index - 2;
        var denominator: i64 = index + 1;
        const common = (@as(i64, if (@rem(denominator, 3) == 0) 3 else 1)) * (if (@rem(denominator, 2) == 0) @as(i64, 2) else 1);
        numerator = @divTrunc(numerator, common);
        denominator = @divTrunc(denominator, common);
        value = @divTrunc(value, denominator) * numerator;
    }
    return value;
}
