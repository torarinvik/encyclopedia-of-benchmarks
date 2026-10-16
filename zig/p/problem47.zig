fn distinctPrimeFactorCount(value_input: i64) i64 {
    var value = value_input;
    var count: i64 = 0;
    var divisor: i64 = 2;
    while (divisor * divisor <= value) : (divisor += 1) {
        if (@mod(value, divisor) == 0) {
            count += 1;
            while (@mod(value, divisor) == 0) value = @divTrunc(value, divisor);
        }
    }
    if (value > 1) count += 1;
    return count;
}

pub export fn problem47(n: i64) i64 {
    if (n < 1 or n > 4) return -1;
    var value: i64 = 2;
    var run_length: i64 = 0;
    while (true) : (value += 1) {
        if (distinctPrimeFactorCount(value) == n) {
            run_length += 1;
        } else {
            run_length = 0;
        }
        if (run_length == n) return value - n + 1;
    }
}
