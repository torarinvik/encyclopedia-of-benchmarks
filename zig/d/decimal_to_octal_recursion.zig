/// Recursively encode octal digits as a decimal integer.
fn encodeOctalDigits(value: i64) i64 {
    if (value == 0) return 0;
    return encodeOctalDigits(@divTrunc(value, 8)) * 10 + @rem(value, 8);
}

export fn decimal_to_octal_recursion(value: i64) i64 {
    if (value < 0 or value > 295600127) return -1;
    return encodeOctalDigits(value);
}
