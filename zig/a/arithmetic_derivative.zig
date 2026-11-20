const MAX_N: i64 = 1_000_000_000_000;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn derivativeFromFactors(value: i64) i64 {
    if (value < 2) return 0;
    const original = value;
    var remaining = value;
    var derivative: i64 = 0;
    var factor: i64 = 2;
    while (factor <= @divTrunc(remaining, factor)) {
        if (@rem(remaining, factor) == 0) {
            var exponent: i64 = 0;
            while (@rem(remaining, factor) == 0) {
                remaining = @divTrunc(remaining, factor);
                exponent += 1;
            }
            derivative += @divTrunc(original, factor) * exponent;
        }
        if (factor == 2) {
            factor = 3;
        } else {
            factor += 2;
        }
    }
    if (remaining > 1) derivative += @divTrunc(original, remaining);
    return derivative;
}

export fn arithmetic_derivative(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1) return -1;
    const n = input[0];
    if (n < 0 or n > MAX_N) return -1;
    return derivativeFromFactors(n);
}
