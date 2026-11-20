module generalized_chinese_remainder_theorem;

const long MAX_PRODUCT = 16777216;

fn long modular_inverse(long value, long modulus) {
    long old_remainder = value % modulus, remainder = modulus;
    long old_coefficient = 1, coefficient = 0;
    while (remainder != 0) {
        long quotient = old_remainder / remainder;
        long next_remainder = old_remainder - quotient * remainder;
        old_remainder = remainder;
        remainder = next_remainder;
        long next_coefficient = old_coefficient - quotient * coefficient;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    old_coefficient %= modulus;
    return old_coefficient < 0 ? old_coefficient + modulus : old_coefficient;
}

fn long generalized_chinese_remainder_theorem(long* input, usz length) @export("generalized_chinese_remainder_theorem") {
    if (input == null || length < 1 || length > 10) return -1;
    long count = input[0];
    if (count < 1 || count > 4 || length != 1 + 2 * (usz)count) return -1;
    long product = 1;
    for (usz index = 0; index < (usz)count; index++) {
        long residue = input[1 + 2 * index], modulus = input[2 + 2 * index];
        if (modulus < 2 || modulus > 64 || residue < 0 || residue >= modulus) return -1;
        if (product > MAX_PRODUCT / modulus) return -1;
        product *= modulus;
    }

    long[65] powers;
    long[65] residues;
    for (usz i = 0; i < 65; i++) { powers[i] = 0; residues[i] = 0; }
    for (usz index = 0; index < (usz)count; index++) {
        long residue = input[1 + 2 * index], remaining = input[2 + 2 * index];
        for (long prime = 2; prime <= remaining; prime++) {
            if (remaining % prime != 0) continue;
            long prime_power = 1;
            do {
                remaining /= prime;
                prime_power *= prime;
            } while (remaining % prime == 0);
            if (prime_power > powers[(usz)prime]) {
                powers[(usz)prime] = prime_power;
                residues[(usz)prime] = residue % prime_power;
            }
        }
    }
    for (usz index = 0; index < (usz)count; index++) {
        long residue = input[1 + 2 * index], remaining = input[2 + 2 * index];
        for (long prime = 2; prime <= remaining; prime++) {
            if (remaining % prime != 0) continue;
            long prime_power = 1;
            do {
                remaining /= prime;
                prime_power *= prime;
            } while (remaining % prime == 0);
            if (residues[(usz)prime] % prime_power != residue % prime_power) return -2;
        }
    }

    long solution = 0, combined_modulus = 1;
    for (usz prime = 2; prime <= 64; prime++) {
        long modulus = powers[prime];
        if (modulus == 0) continue;
        long inverse = modular_inverse(combined_modulus % modulus, modulus);
        long difference = (residues[prime] - solution % modulus) % modulus;
        if (difference < 0) difference += modulus;
        long multiplier = difference * inverse % modulus;
        solution += combined_modulus * multiplier;
        combined_modulus *= modulus;
        solution %= combined_modulus;
    }
    return solution;
}
