module chinese_remainder_theorem;

const usz MAX_INPUTS = 8;
const long MAX_MODULUS = 1000;

fn long crt_modular_inverse(long value, long modulus)
{
    long old_remainder = value % modulus;
    long remainder = modulus;
    long old_coefficient = 1;
    long coefficient = 0;
    while (remainder != 0) {
        long quotient = old_remainder / remainder;
        long next_remainder = old_remainder - quotient * remainder;
        old_remainder = remainder;
        remainder = next_remainder;
        long next_coefficient = old_coefficient - quotient * coefficient;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    if (old_remainder != 1) return -1;
    old_coefficient %= modulus;
    return old_coefficient < 0 ? old_coefficient + modulus : old_coefficient;
}

fn long chinese_remainder_theorem(long* values, usz length) @export("chinese_remainder_theorem")
{
    if (length < 2 || length > MAX_INPUTS || length % 2 != 0) return -1;
    long result = 0;
    long product = 1;
    for (usz index = 0; index < length; index += 2) {
        long residue = values[index];
        long modulus = values[index + 1];
        if (modulus < 2 || modulus > MAX_MODULUS || residue < 0 || residue >= modulus) return -1;
        long inverse = crt_modular_inverse(product % modulus, modulus);
        if (inverse < 0) return -1;
        long difference = residue - result % modulus;
        if (difference < 0) difference += modulus;
        long factor = difference * inverse % modulus;
        result += product * factor;
        product *= modulus;
    }
    return result;
}
