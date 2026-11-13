const MAX_QUERIES: usize = 32;
const MAX_N: usize = 128;
const MAX_PARSEABLE: usize = 68;
const MAX_MODULUS: i64 = 1_000_000_000;

fn is_prime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn pow_mod(base_value: i64, exponent_value: i64, modulus: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@as(u64, @bitCast(exponent)) & 1 != 0) result = @rem(result * base, modulus);
        base = @rem(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

export fn binomial_coefficient_prime_power(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_PARSEABLE) return -1;
    const input = input_opt.?;
    const p = input[0];
    const e = input[1];
    const q_value = input[2];
    if (p < 2 or p > 31 or !is_prime(p) or e < 1 or e > 8 or q_value < 0 or q_value > MAX_QUERIES) return -1;
    var modulus: i64 = 1;
    var exp_index: i64 = 0;
    while (exp_index < e) : (exp_index += 1) {
        modulus *= p;
        if (modulus > MAX_MODULUS) return -1;
    }
    const q: usize = @intCast(q_value);
    if (length != 3 + 2 * q) return -1;
    for (0..q) |i| {
        const n = input[3 + 2 * i];
        const k = input[4 + 2 * i];
        if (n < 0 or n > MAX_N or k < 0 or k > n) return -1;
    }
    if (q == 0) return 0;
    const required = 4 * q;
    if (output_opt == null or capacity < required) return -2;

    var unit_prefix = [_]i64{0} ** (MAX_N + 1);
    var p_free_factorial = [_]i64{0} ** (MAX_N + 1);
    var valuation = [_]u16{0} ** (MAX_N + 1);
    var residues = [_]u32{0} ** MAX_QUERIES;
    unit_prefix[0] = 1;
    p_free_factorial[0] = 1;
    const p_usize: usize = @intCast(p);
    for (1..MAX_N + 1) |n| {
        const factor: i64 = if (n % p_usize == 0) 1 else @intCast(n);
        unit_prefix[n] = @rem(unit_prefix[n - 1] * factor, modulus);
        p_free_factorial[n] = @rem(unit_prefix[n] * p_free_factorial[n / p_usize], modulus);
        valuation[n] = @intCast(n / p_usize + valuation[n / p_usize]);
    }
    const phi = @divTrunc(modulus, p) * (p - 1);
    for (0..q) |i| {
        const n: usize = @intCast(input[3 + 2 * i]);
        const k: usize = @intCast(input[4 + 2 * i]);
        const p_power = @as(usize, valuation[n]) - @as(usize, valuation[k]) - @as(usize, valuation[n - k]);
        if (p_power < @as(usize, @intCast(e))) {
            const denominator = @rem(p_free_factorial[k] * p_free_factorial[n - k], modulus);
            const inverse = pow_mod(denominator, phi - 1, modulus);
            const prime_factor = pow_mod(p, @intCast(p_power), modulus);
            residues[i] = @intCast(@rem(@rem(p_free_factorial[n] * inverse, modulus) * prime_factor, modulus));
        }
    }
    const output = output_opt.?;
    for (0..q) |i| {
        for (0..4) |byte| output[4 * i + byte] = @truncate(residues[i] >> @intCast(8 * byte));
    }
    return @intCast(required);
}
