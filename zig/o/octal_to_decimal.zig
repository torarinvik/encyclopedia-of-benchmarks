/// Convert most-significant-first octal digits to a signed 64-bit value.
export fn octal_to_decimal(digits: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 21) return -1;
    var result: i64 = 0;
    for (0..length) |index| {
        const digit = digits[index];
        if (digit < 0 or digit > 7) return -1;
        result = result * 8 + digit;
    }
    return result;
}
