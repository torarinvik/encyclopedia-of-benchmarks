export fn exponentiation(base: i64, exponent: i64) i64 {
    if (base < 0 or base > 255 or exponent < 0 or exponent > 7) return -1;
    var result: i64 = 1;
    var i: i64 = 0;
    while (i < exponent) : (i += 1) result *= base;
    return result;
}
