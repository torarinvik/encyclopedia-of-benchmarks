module steed_continued_fraction_convergents;

const long MODULUS = 998244353;
const usz MAX_INPUT_LENGTH = 19;

fn long mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn bool divisors_are_nonzero(long *input, usz levels) {
    if (input[2] == 0) return false;
    long d_value = mod_pow(input[2], MODULUS - 2);
    for (usz level = 2; level <= levels; level++) {
        long denominator = (d_value * input[2 * level + 1] + input[2 * level]) % MODULUS;
        if (denominator == 0) return false;
        d_value = mod_pow(denominator, MODULUS - 2);
    }
    return true;
}

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long steed_continued_fraction_convergents(long *input, usz length,
    char *output, usz capacity) @export("steed_continued_fraction_convergents") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long levels_value = input[0];
    if (levels_value < 1 || levels_value > 8) return -1;
    usz levels = (usz)levels_value;
    if (length != 2 + 2 * levels) return -1;
    for (usz index = 1; index < length; index++)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    if (!divisors_are_nonzero(input, levels)) return -1;

    usz required = 8 * (levels + 2);
    if (output == null || capacity < required) return -2;
    store_i64_le(output, 0, levels_value + 1);
    long current = input[1];
    store_i64_le(output, 8, current);
    long d_value = mod_pow(input[2], MODULUS - 2);
    long delta = input[3] * d_value % MODULUS;
    current = (current + delta) % MODULUS;
    store_i64_le(output, 16, current);
    for (usz level = 2; level <= levels; level++) {
        long b_value = input[2 * level];
        long a_value = input[2 * level + 1];
        long denominator = (d_value * a_value + b_value) % MODULUS;
        d_value = mod_pow(denominator, MODULUS - 2);
        long factor = (b_value * d_value + MODULUS - 1) % MODULUS;
        delta = factor * delta % MODULUS;
        current = (current + delta) % MODULUS;
        store_i64_le(output, 8 * (level + 1), current);
    }
    return (long)required;
}
