const MAX_VALUE: i64 = 1_000_000;

export fn lucas_carmichael_number_predicate(raw: ?[*]const i64, length: usize) i64 {
    const input = raw orelse return -1;
    if (length != 1) return -1;
    const value = input[0];
    if (value < 1 or value > MAX_VALUE) return -1;

    var remaining = value;
    var divisor: i64 = 2;
    var composite = false;
    while (divisor <= @divTrunc(remaining, divisor)) : (divisor += 1) {
        if (@rem(remaining, divisor) == 0) {
            composite = true;
            var exponent: usize = 0;
            while (@rem(remaining, divisor) == 0) {
                remaining = @divTrunc(remaining, divisor);
                exponent += 1;
            }
            if (exponent != 1 or @rem(value + 1, divisor + 1) != 0) return 0;
        }
    }
    if (remaining > 1) {
        if (!composite or @rem(value + 1, remaining + 1) != 0) return 0;
    }
    return if (composite) 1 else 0;
}
