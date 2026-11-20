const MAX_N: i64 = 100_000;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn factorSumCounted(value_arg: i64) i64 {
    var value = value_arg;
    var total: i64 = 0;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        while (@rem(value, divisor) == 0) {
            total += divisor;
            value = @divTrunc(value, divisor);
        }
    }
    if (value > 1) total += value;
    return total;
}

export fn ruth_aaron_number_predicate(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1) return -1;
    const n = values[0];
    if (n < 1 or n > MAX_N) return -1;
    return if (factorSumCounted(n) == factorSumCounted(n + 1)) 1 else 0;
}
