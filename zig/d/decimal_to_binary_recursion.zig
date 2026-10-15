/// Recursively encode binary digits as a decimal integer, for inputs 0..1023.
fn encodeBinaryDigits(value: i64) i64 {
    if (value == 0) return 0;
    return @rem(value, 2) + 10 * encodeBinaryDigits(@divTrunc(value, 2));
}

export fn decimal_to_binary_recursion(value: i64) i64 {
    if (value < 0 or value > 1023) return -1;
    return encodeBinaryDigits(value);
}
