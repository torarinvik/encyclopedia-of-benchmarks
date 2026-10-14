/// Convert most-significant-first hexadecimal digits to a signed 64-bit value.
export fn hexadecimal_to_decimal(digits: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 16) return -1;
    if (length == 16 and digits[0] > 7) return -1;
    var result: i64 = 0;
    for (0..length) |index| {
        const digit = digits[index];
        if (digit < 0 or digit > 15) return -1;
        result = result * 16 + digit;
    }
    return result;
}
