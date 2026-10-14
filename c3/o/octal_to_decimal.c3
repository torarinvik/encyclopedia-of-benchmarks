module octal_to_decimal;

// Convert most-significant-first octal digits to a signed 64-bit value.
fn long octal_to_decimal(long* digits, usz length) @export("octal_to_decimal")
{
    if (length == 0 || length > 21) return -1;
    long result = 0;
    for (usz index = 0; index < length; index++) {
        long digit = digits[index];
        if (digit < 0 || digit > 7) return -1;
        result = result * 8 + digit;
    }
    return result;
}
