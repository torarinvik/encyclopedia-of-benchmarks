module any_base_to_decimal;

// Fold most-significant-first digits in base 2 through 36 into i64.
fn long any_base_to_decimal(long* input, usz length) @export("any_base_to_decimal") {
    if (length < 2 || length > 65) return -1;
    long base = input[0];
    if (base < 2 || base > 36) return -1;
    long value = 0;
    for (usz index = 1; index < length; index++) {
        long digit = input[index];
        if (digit < 0 || digit >= base) return -1;
        if (value > (9223372036854775807 - digit) / base) return -1;
        value = value * base + digit;
    }
    return value;
}
