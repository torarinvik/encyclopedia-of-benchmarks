module continued_fraction_forward_series_recurrence;

const long MODULUS = 998244353;
const usz MAX_INPUT_LENGTH = 11;

fn long mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn long next_numerator(long coefficient, long rho) {
    return coefficient * ((rho + 1) % MODULUS) % MODULUS;
}

fn bool divisors_are_nonzero(long *input, usz count) {
    long rho = 0;
    for (usz index = 1; index < count; index++) {
        long numerator = next_numerator(input[index + 1], rho);
        long denominator = (1 + MODULUS - numerator) % MODULUS;
        if (denominator == 0) return false;
        rho = numerator * mod_pow(denominator, MODULUS - 2) % MODULUS;
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

fn long continued_fraction_forward_series_recurrence(long *input, usz length,
    char *output, usz capacity) @export("continued_fraction_forward_series_recurrence") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 2 || count_value > 9) return -1;
    usz count = (usz)count_value;
    if (length != count + 1) return -1;
    for (usz index = 1; index <= count; index++)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    if (!divisors_are_nonzero(input, count)) return -1;
    usz required = 8 * (count + 1);
    if (output == null || capacity < required) return -2;

    store_i64_le(output, 0, count_value);
    long rho = 0, term = input[1], sum = input[1];
    store_i64_le(output, 8, sum);
    for (usz index = 1; index < count; index++) {
        long numerator = next_numerator(input[index + 1], rho);
        long denominator = (1 + MODULUS - numerator) % MODULUS;
        rho = numerator * mod_pow(denominator, MODULUS - 2) % MODULUS;
        term = rho * term % MODULUS;
        sum = (sum + term) % MODULUS;
        store_i64_le(output, 8 * (index + 1), sum);
    }
    return (long)required;
}
