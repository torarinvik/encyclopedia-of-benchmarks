module hexadecimal_to_decimal;

// Convert most-significant-first hexadecimal digits to a signed 64-bit value.
fn long hexadecimal_to_decimal(long* digits, usz length) @export("hexadecimal_to_decimal")
{
    if (length == 0 || length > 16) return -1;
    if (length == 16 && digits[0] > 7) return -1;
    long result = 0;
    for (usz index = 0; index < length; index++) {
        long digit = digits[index];
        if (digit < 0 || digit > 15) return -1;
        result = result * 16 + digit;
    }
    return result;
}
