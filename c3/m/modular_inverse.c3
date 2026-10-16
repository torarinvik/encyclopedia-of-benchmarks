module modular_inverse;

fn long normalized_mod(long value, long modulus) {
    long remainder = value % modulus;
    if (remainder < 0) remainder += modulus;
    return remainder;
}

fn long modular_inverse(long a, long modulus) @export("modular_inverse") {
    if (a < 0 || a > 1000000 || modulus < 2 || modulus > 1000000) return -1;

    long old_remainder = normalized_mod(a, modulus);
    long remainder = modulus;
    long old_coefficient = 1;
    long coefficient = 0;
    while (remainder != 0) {
        long quotient = old_remainder / remainder;
        long next_remainder = old_remainder - quotient * remainder;
        long next_coefficient = old_coefficient - quotient * coefficient;
        old_remainder = remainder;
        remainder = next_remainder;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    if (old_remainder != 1) return -1;
    return normalized_mod(old_coefficient, modulus);
}
