/// Deterministic Miller-Rabin for signed 32-bit inputs.
fn modPower(base_value: i64, exponent_value: i64, modulus: i64) i64 {
    var base = @rem(base_value, modulus);
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = @rem(result * base, modulus);
        base = @rem(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn passesBase(n: i64, base: i64, odd_part: i64, powers_of_two: i64) bool {
    var value = modPower(base, odd_part, n);
    if (value == 1 or value == n - 1) return true;
    var round: i64 = 1;
    while (round < powers_of_two) : (round += 1) {
        value = @rem(value * value, n);
        if (value == n - 1) return true;
    }
    return false;
}

export fn miller_rabin(n: i64) i64 {
    if (n < 2) return 0;
    if (n > 2147483647) return -1;
    const small_primes = [_]i64{ 2, 3, 5, 7 };
    for (small_primes) |prime| {
        if (n == prime) return 1;
        if (@rem(n, prime) == 0) return 0;
    }

    var odd_part = n - 1;
    var powers_of_two: i64 = 0;
    while (@rem(odd_part, 2) == 0) {
        odd_part = @divTrunc(odd_part, 2);
        powers_of_two += 1;
    }
    for (small_primes) |base| {
        if (!passesBase(n, base, odd_part, powers_of_two)) return 0;
    }
    return 1;
}
