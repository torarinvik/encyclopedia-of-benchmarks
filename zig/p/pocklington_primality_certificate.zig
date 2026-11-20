/// Pocklington n-1 certificate verification for a bounded input frame.
const MAX_N: i64 = 65_535;
const MAX_FACTORS: i64 = 6;
const MAX_EXPONENT: i64 = 16;
const MAX_LENGTH: usize = 22;

fn gcdI64(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor * divisor <= value) {
        if (@rem(value, divisor) == 0) return false;
        if (divisor == 2) divisor = 3 else divisor += 2;
    }
    return true;
}

fn powMod(base_value: i64, exponent_value: i64, modulus: i64) i64 {
    var result: i64 = 1;
    var factor = @rem(base_value, modulus);
    var exponent = exponent_value;
    while (exponent > 0) {
        if (@rem(exponent, 2) == 1) result = @rem(result * factor, modulus);
        factor = @rem(factor * factor, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn verifyCertificate(values: []const i64) i64 {
    if (values.len < 2 or values.len > MAX_LENGTH) return -1;
    const n = values[0];
    const count_value = values[1];
    if (n < 3 or n > MAX_N or count_value < 1 or count_value > MAX_FACTORS) return -1;
    const count: usize = @intCast(count_value);
    if (values.len != 3 + 3 * count) return -1;

    var factored_part: i64 = 1;
    var previous_prime: i64 = 1;
    for (0..count) |index| {
        const offset = 2 + 3 * index;
        const prime = values[offset];
        const exponent = values[offset + 1];
        const witness = values[offset + 2];
        if (prime <= previous_prime or prime < 2 or exponent < 1 or exponent > MAX_EXPONENT
            or witness < 1 or witness >= n or !isPrime(prime)) return -1;
        previous_prime = prime;
        var power_index: i64 = 0;
        while (power_index < exponent) : (power_index += 1) {
            if (factored_part > @divTrunc(n - 1, prime)) return -1;
            factored_part *= prime;
        }
    }
    const cofactor = values[2 + 3 * count];
    if (cofactor < 1 or cofactor >= n or factored_part * cofactor != n - 1) return -1;
    if (factored_part * factored_part <= n) return 0;

    for (0..count) |index| {
        const offset = 2 + 3 * index;
        const prime = values[offset];
        const witness = values[offset + 2];
        if (powMod(witness, n - 1, n) != 1) return 0;
        const reduced = powMod(witness, @divTrunc(n - 1, prime), n);
        const difference = @rem(reduced + n - 1, n);
        if (gcdI64(difference, n) != 1) return 0;
    }
    return 1;
}

export fn pocklington_primality_certificate(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_LENGTH) return -1;
    return verifyCertificate(input.?[0..length]);
}
