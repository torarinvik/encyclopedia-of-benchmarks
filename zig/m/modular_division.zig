/// Fermat modular division for a bounded prime modulus.
fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn modularPower(base_input: i64, exponent_input: u64, modulus: i64) i64 {
    var base = @rem(base_input, modulus);
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = @rem(result * base, modulus);
        exponent >>= 1;
        base = @rem(base * base, modulus);
    }
    return result;
}

export fn modular_division(values: [*]const i64, length: usize) i64 {
    if (length != 3) return -1;
    const numerator = values[0];
    const denominator = values[1];
    const modulus = values[2];
    if (numerator < 0 or numerator > 1000000000000 or denominator < 0 or denominator > 1000000000000 or
        modulus < 2 or modulus > 1000000 or !isPrime(modulus) or @rem(denominator, modulus) == 0) return -1;
    const inverse = modularPower(denominator, @intCast(modulus - 2), modulus);
    return @rem(@rem(numerator, modulus) * inverse, modulus);
}
