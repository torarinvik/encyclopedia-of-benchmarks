fn modexpt(base: i64, exponent: i64, modulus: i64) i64 {
    if (exponent == 1) return base;
    if (@mod(exponent, 2) == 0) {
        const half = @mod(modexpt(base, @divTrunc(exponent, 2), modulus), modulus);
        return @mod(half * half, modulus);
    }
    return @mod(base * modexpt(base, exponent - 1, modulus), modulus);
}

export fn problem188(base: i64, height: i64, digits: i64) i64 {
    if (base < 1 or base > 1_000_000_000 or @mod(base, 10) == 0
        or height < 1 or height > 10_000 or digits < 1 or digits > 8) return -1;
    var modulus: i64 = 1;
    var index: i64 = 0;
    while (index < digits) : (index += 1) modulus *= 10;
    var result = base;
    var level: i64 = 1;
    while (level < height) : (level += 1) result = modexpt(base, result, modulus);
    return result;
}
