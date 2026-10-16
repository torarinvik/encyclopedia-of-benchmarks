// Return the unpadded decimal suffix of the non-Mersenne prime expression.
module problem97;

const long MAX_DIGITS = 18;
const long POWER_EXPONENT = 7830457;

fn long multiply_mod(long left, long right, long modulus) {
    long result = 0;
    while (right > 0) {
        if (right % 2 != 0) result = (result + left) % modulus;
        left = (left + left) % modulus;
        right /= 2;
    }
    return result;
}

fn long problem97(long digits) @export("problem97") {
    if (digits < 0 || digits > MAX_DIGITS) return -1;
    long modulus = 1;
    for (long index = 0; index < digits; index++) modulus *= 10;
    long power = 1 % modulus;
    long base = 2 % modulus;
    long exponent = POWER_EXPONENT;
    while (exponent > 0) {
        if (exponent % 2 != 0) power = multiply_mod(power, base, modulus);
        base = multiply_mod(base, base, modulus);
        exponent /= 2;
    }
    return (multiply_mod(28433, power, modulus) + 1) % modulus;
}
