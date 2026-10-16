/// Fermat modular inverse via prime validation and binary exponentiation.
fn is_prime(value: i64) bool {
    if (value <= 1) return false;
    var divisor: i64 = 2;
    while (divisor * divisor <= value) : (divisor += 1) {
        if (@mod(value, divisor) == 0) return false;
    }
    return true;
}

fn binary_exponentiation(base_input: i64, exponent_input: i64, modulus: i64) i64 {
    var base = @mod(base_input, modulus);
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) : (exponent = @divTrunc(exponent, 2)) {
        if (@mod(exponent, 2) != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
    }
    return result;
}

export fn modular_inverse_fermat_little_theorem(a: i64, m: i64) i64 {
    if (a < -1_000_000 or a > 1_000_000 or m < 2 or m > 1_000_000) return -1;
    if (a == 0 or a <= -m or a >= m or !is_prime(m)) return -1;
    var normalized = a;
    while (normalized < 0) : (normalized += m) {}
    return binary_exponentiation(normalized, m - 2, m);
}
