const MAX_P: i64 = 1009;
const TABLE_LEN: usize = 1009;

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn powMod(base_value: i64, exponent_value: i64, modulus: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = @rem(result * base, modulus);
        base = @rem(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

export fn binomial_coefficient_lucas(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 3) return -1;
    const input = input_opt.?;
    const n = input[0];
    const k = input[1];
    const p = input[2];
    if (n < 0 or k < 0 or k > n or p < 2 or p > MAX_P or !isPrime(p)) return -1;

    const p_usize: usize = @intCast(p);
    var factorial = [_]i64{0} ** TABLE_LEN;
    var inverse_factorial = [_]i64{0} ** TABLE_LEN;
    factorial[0] = 1;
    var i: usize = 1;
    while (i < p_usize) : (i += 1) {
        factorial[i] = @rem(factorial[i - 1] * @as(i64, @intCast(i)), p);
    }
    inverse_factorial[p_usize - 1] = powMod(factorial[p_usize - 1], p - 2, p);
    i = p_usize - 1;
    while (i > 0) : (i -= 1) {
        inverse_factorial[i - 1] = @rem(inverse_factorial[i] * @as(i64, @intCast(i)), p);
    }

    var remaining_n = n;
    var remaining_k = k;
    var result: i64 = 1;
    while (remaining_n > 0 or remaining_k > 0) {
        const n_digit: usize = @intCast(@rem(remaining_n, p));
        const k_digit: usize = @intCast(@rem(remaining_k, p));
        if (k_digit > n_digit) return 0;
        result = @rem(result * factorial[n_digit], p);
        result = @rem(result * inverse_factorial[k_digit], p);
        result = @rem(result * inverse_factorial[n_digit - k_digit], p);
        remaining_n = @divTrunc(remaining_n, p);
        remaining_k = @divTrunc(remaining_k, p);
    }
    return result;
}
