fn gcdI64(left: i64, right: i64) i64 {
    var a = left;
    var b = right;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

export fn problem33(digit_len: i64) i64 {
    if (digit_len < 0 or digit_len > 5) return -1;
    var upper: i64 = 1;
    for (0..@intCast(digit_len)) |_| upper *= 10;
    var result: f64 = 1.0;
    var denominator: i64 = 11;
    var numerator: i64 = 11;
    while (numerator < upper) : (numerator += 1) {
        while (denominator <= 99) : (denominator += 1) {
            if (numerator != denominator and @rem(numerator, 10) == @divTrunc(denominator, 10) and
                @rem(denominator, 10) != 0 and
                @as(f64, @floatFromInt(@divTrunc(numerator, 10))) /
                    @as(f64, @floatFromInt(@rem(denominator, 10))) ==
                    @as(f64, @floatFromInt(numerator)) / @as(f64, @floatFromInt(denominator)))
            {
                const divisor = gcdI64(numerator, denominator);
                result *= @as(f64, @floatFromInt(@divTrunc(denominator, divisor))) /
                          @as(f64, @floatFromInt(@divTrunc(numerator, divisor)));
            }
        }
        denominator = 10;
    }
    return @intFromFloat(result);
}
