export fn digital_root(n: i64) i64 {
    if (n < 0) return -1;
    var value = n;
    while (value >= 10) {
        var digits = value;
        var total: i64 = 0;
        while (digits > 0) {
            total += @rem(digits, 10);
            digits = @divTrunc(digits, 10);
        }
        value = total;
    }
    return value;
}
