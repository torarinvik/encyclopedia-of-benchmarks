fn powPositive(base: f64, exponent: i64) f64 {
    if (exponent == 0) return 1.0;
    var mask: i64 = 1;
    while (mask <= @divTrunc(exponent, 2)) : (mask <<= 1) {}
    var result = base;
    mask >>= 1;
    while (mask != 0) : (mask >>= 1) {
        result *= result;
        if ((exponent & mask) != 0) result *= base;
    }
    return result;
}

export fn powx_n(base: f64, exponent: i32) f64 {
    if (exponent == 0) return 1.0;
    const wide: i64 = @as(i64, exponent);
    if (exponent == -2147483648) return 1.0 / (powPositive(base, 2147483647) * base);
    if (exponent < 0) return 1.0 / powPositive(base, -wide);
    return powPositive(base, wide);
}
