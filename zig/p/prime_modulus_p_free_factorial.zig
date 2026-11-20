const MAX_PRIME: i64 = 1009;
const FACTORIAL_CAPACITY: usize = 1009;

fn is_prime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

export fn prime_modulus_p_free_factorial(
    input: [*c]const i64,
    length: usize,
) i64 {
    if (input == null or length != 2) return -1;
    const n = input[0];
    const prime = input[1];
    if (n < 0 or prime < 2 or prime > MAX_PRIME or !is_prime(prime)) return -1;

    const prime_size: usize = @intCast(prime);
    var factorial: [FACTORIAL_CAPACITY]i64 = @splat(0);
    factorial[0] = 1;
    for (1..prime_size) |value| {
        factorial[value] = @rem(factorial[value - 1] * @as(i64, @intCast(value)), prime);
    }

    var result: i64 = 1;
    var remaining = n;
    while (remaining > 0) {
        const quotient = @divTrunc(remaining, prime);
        const residue: usize = @intCast(@rem(remaining, prime));
        var block = factorial[residue];
        if (@rem(quotient, 2) != 0) block = prime - block;
        result = @rem(result * block, prime);
        remaining = quotient;
    }
    return result;
}
