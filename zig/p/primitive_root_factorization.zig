const MAX_PRIME: i64 = 4093;

fn is_prime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor * divisor <= value) : (divisor += 1) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn power_mod(base_input: i64, exponent_input: i64, modulus: i64) i64 {
    var base = base_input;
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

export fn primitive_root_factorization(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    const prime = input[0];
    if (prime < 2 or prime > MAX_PRIME or !is_prime(prime)) return -1;
    if (prime == 2) return 1;

    var factors: [16]i64 = undefined;
    var factor_count: usize = 0;
    var remaining = prime - 1;
    var divisor: i64 = 2;
    while (divisor * divisor <= remaining) : (divisor += 1) {
        if (remaining % divisor == 0) {
            factors[factor_count] = divisor;
            factor_count += 1;
            while (remaining % divisor == 0) remaining /= divisor;
        }
    }
    if (remaining > 1) {
        factors[factor_count] = remaining;
        factor_count += 1;
    }

    var candidate: i64 = 2;
    while (candidate < prime) : (candidate += 1) {
        var valid = true;
        for (0..factor_count) |index| {
            if (power_mod(candidate, (prime - 1) / factors[index], prime) == 1) {
                valid = false;
                break;
            }
        }
        if (valid) return candidate;
    }
    return -1;
}
