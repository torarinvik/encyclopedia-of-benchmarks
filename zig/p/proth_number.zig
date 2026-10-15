/// Preserve the source's factor-of-two reduction for Proth membership.
export fn is_proth_number(input: i64) i64 {
    if (input <= 0) return -1;
    if (input == 1) return 0;

    var remainder = input - 1;
    var exponent: u6 = 0;
    while (@mod(remainder, 2) == 0) {
        exponent += 1;
        remainder = @divTrunc(remainder, 2);
    }
    return if (remainder < (@as(i64, 1) << exponent)) 1 else 0;
}
