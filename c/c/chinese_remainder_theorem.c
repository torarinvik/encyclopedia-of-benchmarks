/* Solve pairwise-coprime congruences with incremental CRT and extended Euclid. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUTS 8
#define MAX_MODULUS 1000

static int64_t modular_inverse(int64_t value, int64_t modulus)
{
    int64_t old_remainder = value % modulus;
    int64_t remainder = modulus;
    int64_t old_coefficient = 1;
    int64_t coefficient = 0;
    while (remainder != 0) {
        const int64_t quotient = old_remainder / remainder;
        const int64_t next_remainder = old_remainder - quotient * remainder;
        old_remainder = remainder;
        remainder = next_remainder;
        const int64_t next_coefficient = old_coefficient - quotient * coefficient;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    if (old_remainder != 1) return -1;
    old_coefficient %= modulus;
    return old_coefficient < 0 ? old_coefficient + modulus : old_coefficient;
}

int64_t chinese_remainder_theorem(const int64_t *values, size_t length)
{
    if (length < 2 || length > MAX_INPUTS || length % 2 != 0) return -1;
    int64_t result = 0;
    int64_t product = 1;
    for (size_t index = 0; index < length; index += 2) {
        const int64_t residue = values[index];
        const int64_t modulus = values[index + 1];
        if (modulus < 2 || modulus > MAX_MODULUS || residue < 0 || residue >= modulus) return -1;
        const int64_t inverse = modular_inverse(product % modulus, modulus);
        if (inverse < 0) return -1;
        int64_t difference = residue - result % modulus;
        if (difference < 0) difference += modulus;
        const int64_t factor = (difference * inverse) % modulus;
        result += product * factor;
        product *= modulus;
    }
    return result;
}
