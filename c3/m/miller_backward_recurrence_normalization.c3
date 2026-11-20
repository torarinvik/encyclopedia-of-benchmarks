module miller_backward_recurrence_normalization;

const long MODULUS = 998244353;
const usz MAX_INPUT_LENGTH = 35;

fn long mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long miller_backward_recurrence_normalization(long *input, usz length,
    char *output, usz capacity) @export("miller_backward_recurrence_normalization") {
    if (input == null || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    long levels_value = input[0];
    if (levels_value < 1 || levels_value > 8) return -1;
    usz levels = (usz)levels_value;
    if (length != 4 * levels + 2) return -1;
    for (usz index = 1; index < length; index++)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    for (usz level = 1; level <= levels; level++)
        if (input[3 * level] == 0) return -1;

    long[10] trial = {};
    trial[levels] = 1;
    trial[levels + 1] = 0;
    for (usz level = levels; level > 0; level--) {
        long a_value = input[3 * level - 2];
        long b_value = input[3 * level - 1];
        long c_value = input[3 * level];
        long positive = b_value * trial[level] % MODULUS;
        long negative = a_value * trial[level + 1] % MODULUS;
        long numerator = (positive + MODULUS - negative) % MODULUS;
        trial[level - 1] = numerator * mod_pow(c_value, MODULUS - 2) % MODULUS;
    }
    usz lambda_start = 3 * levels + 1;
    long normalizer = 0;
    for (usz index = 0; index <= levels; index++)
        normalizer = (normalizer + input[lambda_start + index] * trial[index]) % MODULUS;
    if (normalizer == 0) return -1;
    long scale = mod_pow(normalizer, MODULUS - 2);
    usz required = 8 * (levels + 2);
    if (output == null || capacity < required) return -2;

    store_i64_le(output, 0, levels_value);
    for (usz index = 0; index <= levels; index++)
        store_i64_le(output, 8 * (index + 1), trial[index] * scale % MODULUS);
    return (long)required;
}
