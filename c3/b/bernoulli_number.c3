module bernoulli_number;

const long MODULUS = 998244353;
const usz MAX_N = 32;

fn long modular_power(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent = exponent >> 1;
    }
    return result;
}

fn long bernoulli_number(long* input, usz length, char* output, usz capacity)
    @export("bernoulli_number") {
    if (input == null || length != 1) return -1;
    long n64 = input[0];
    if (n64 < 0 || n64 > (long)MAX_N) return -1;
    usz n = (usz)n64;
    usz output_bytes = 4 * (n + 1);
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_N + 2] inverse = zeroed;
    long[MAX_N + 1] bernoulli = zeroed;
    inverse[1] = 1;
    for (usz i = 2; i <= n + 1; i += 1) {
        inverse[i] = modular_power((long)i, MODULUS - 2);
    }

    bernoulli[0] = 1;
    for (usz m = 1; m <= n; m += 1) {
        long choose = 1;
        long sum = 0;
        for (usz k = 0; k < m; k += 1) {
            sum = (sum + choose * bernoulli[k]) % MODULUS;
            choose = choose * (long)(m + 1 - k) % MODULUS * inverse[k + 1] % MODULUS;
        }
        bernoulli[m] = ((MODULUS - sum) % MODULUS) * inverse[m + 1] % MODULUS;
    }

    for (usz i = 0; i <= n; i += 1) {
        long value = bernoulli[i];
        output[4 * i] = (char)(value & 255);
        output[4 * i + 1] = (char)((value >> 8) & 255);
        output[4 * i + 2] = (char)((value >> 16) & 255);
        output[4 * i + 3] = (char)((value >> 24) & 255);
    }
    return (long)output_bytes;
}
