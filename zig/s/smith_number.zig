fn is_prime(value: i64) bool {
    if (value == 2) return true;
    if (value < 2 or @rem(value, 2) == 0) return false;
    var divisor: i64 = 3;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 2) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn digit_sum(value_arg: i64) i64 {
    var value = value_arg;
    var sum: i64 = 0;
    while (value != 0) {
        sum += @rem(value, 10);
        value = @divTrunc(value, 10);
    }
    return sum;
}

fn prime_factor_digit_sum(value: i64) i64 {
    var sum: i64 = 0;
    var remainder = value;
    var factor: i64 = 2;
    while (factor <= @divTrunc(value, factor)) : (factor += 1) {
        while (@rem(remainder, factor) == 0) {
            sum += digit_sum(factor);
            remainder = @divTrunc(remainder, factor);
        }
    }
    if (remainder > 1) sum += digit_sum(remainder);
    return sum;
}

export fn smith_number(value: i64) i64 {
    if (value < 1 or value > 2147483647) return -1;
    if (is_prime(value)) return 0;
    return if (digit_sum(value) == prime_factor_digit_sum(value)) 1 else 0;
}
