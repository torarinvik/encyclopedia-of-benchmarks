/// Fold most-significant-first digits in base 2 through 36 into i64.
export fn any_base_to_decimal(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 65) return -1;
    const base = input[0];
    if (base < 2 or base > 36) return -1;
    var value: i64 = 0;
    for (1..length) |index| {
        const digit = input[index];
        if (digit < 0 or digit >= base) return -1;
        if (value > @divTrunc(9223372036854775807 - digit, base)) return -1;
        value = value * base + digit;
    }
    return value;
}
