package modular_inverse

normalized_mod :: proc(value, modulus: i64) -> i64 {
    remainder := value % modulus
    if remainder < 0 {
        remainder += modulus
    }
    return remainder
}

@(export)
modular_inverse :: proc "c" (a, modulus: i64) -> i64 {
    if a < 0 || a > 1_000_000 || modulus < 2 || modulus > 1_000_000 {
        return -1
    }

    old_remainder := normalized_mod(a, modulus)
    remainder := modulus
    old_coefficient: i64 = 1
    coefficient: i64 = 0
    for remainder != 0 {
        quotient := old_remainder / remainder
        next_remainder := old_remainder - quotient * remainder
        next_coefficient := old_coefficient - quotient * coefficient
        old_remainder = remainder
        remainder = next_remainder
        old_coefficient = coefficient
        coefficient = next_coefficient
    }
    if old_remainder != 1 {
        return -1
    }
    return normalized_mod(old_coefficient, modulus)
}
