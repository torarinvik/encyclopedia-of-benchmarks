#include <stddef.h>
#include <stdint.h>

static int64_t modular_inverse(int64_t value, int64_t modulus) {
    int64_t old_remainder = value % modulus, remainder = modulus;
    int64_t old_coefficient = 1, coefficient = 0;
    while (remainder != 0) {
        const int64_t quotient = old_remainder / remainder;
        const int64_t next_remainder = old_remainder - quotient * remainder;
        old_remainder = remainder;
        remainder = next_remainder;
        const int64_t next_coefficient = old_coefficient - quotient * coefficient;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    old_coefficient %= modulus;
    return old_coefficient < 0 ? old_coefficient + modulus : old_coefficient;
}

int64_t generalized_chinese_remainder_theorem(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 10) return -1;
    const int64_t count = input[0];
    if (count < 1 || count > 4 || length != (size_t)(1 + 2 * count)) return -1;

    int64_t product = 1;
    for (int64_t index = 0; index < count; ++index) {
        const int64_t residue = input[1 + 2 * index];
        const int64_t modulus = input[2 + 2 * index];
        if (modulus < 2 || modulus > 64 || residue < 0 || residue >= modulus) return -1;
        if (product > 16777216 / modulus) return -1;
        product *= modulus;
    }

    int64_t powers[65] = {0};
    int64_t residues[65] = {0};
    for (int64_t index = 0; index < count; ++index) {
        const int64_t residue = input[1 + 2 * index];
        int64_t remaining = input[2 + 2 * index];
        for (int64_t prime = 2; prime <= remaining; ++prime) {
            if (remaining % prime != 0) continue;
            int64_t prime_power = 1;
            do {
                remaining /= prime;
                prime_power *= prime;
            } while (remaining % prime == 0);
            if (prime_power > powers[prime]) {
                powers[prime] = prime_power;
                residues[prime] = residue % prime_power;
            }
        }
    }

    for (int64_t index = 0; index < count; ++index) {
        const int64_t residue = input[1 + 2 * index];
        int64_t remaining = input[2 + 2 * index];
        for (int64_t prime = 2; prime <= remaining; ++prime) {
            if (remaining % prime != 0) continue;
            int64_t prime_power = 1;
            do {
                remaining /= prime;
                prime_power *= prime;
            } while (remaining % prime == 0);
            if (residues[prime] % prime_power != residue % prime_power) return -2;
        }
    }

    int64_t solution = 0;
    int64_t combined_modulus = 1;
    for (int64_t prime = 2; prime <= 64; ++prime) {
        const int64_t modulus = powers[prime];
        if (modulus == 0) continue;
        const int64_t inverse = modular_inverse(combined_modulus % modulus, modulus);
        int64_t difference = residues[prime] - solution % modulus;
        difference %= modulus;
        if (difference < 0) difference += modulus;
        const int64_t multiplier = difference * inverse % modulus;
        solution += combined_modulus * multiplier;
        combined_modulus *= modulus;
        solution %= combined_modulus;
    }
    return solution;
}
