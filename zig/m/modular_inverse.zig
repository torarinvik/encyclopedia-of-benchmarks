fn normalizedMod(value: i64, modulus: i64) i64 {
    return @mod(value, modulus);
}

export fn modular_inverse(a: i64, modulus: i64) i64 {
    if (a < 0 or a > 1_000_000 or modulus < 2 or modulus > 1_000_000) return -1;

    var old_remainder = normalizedMod(a, modulus);
    var remainder = modulus;
    var old_coefficient: i64 = 1;
    var coefficient: i64 = 0;
    while (remainder != 0) {
        const quotient = @divTrunc(old_remainder, remainder);
        const next_remainder = old_remainder - quotient * remainder;
        const next_coefficient = old_coefficient - quotient * coefficient;
        old_remainder = remainder;
        remainder = next_remainder;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    if (old_remainder != 1) return -1;
    return normalizedMod(old_coefficient, modulus);
}
