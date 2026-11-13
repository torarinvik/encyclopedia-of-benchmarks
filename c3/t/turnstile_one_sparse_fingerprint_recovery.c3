module turnstile_one_sparse_fingerprint_recovery;

const long MODULUS = 1000000007;

fn long power_mod(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn long turnstile_one_sparse_fingerprint_recovery(long* input, usz length) @export("turnstile_one_sparse_fingerprint_recovery") {
    if (input == null || length < 3 || length > 260) return -1;
    long n = input[0], q = input[1], base = input[2];
    if (n < 1 || n > 64 || q < 0 || q > 128 || base < 1 || base >= MODULUS || length != (usz)(3 + 2 * q)) return -1;
    long mass = 0, weighted = 0, fingerprint = 0;
    for (usz i = 0; i < (usz)q; i += 1) {
        long index = input[3 + 2 * i], delta = input[4 + 2 * i];
        if (index < 0 || index >= n || delta < -1000 || delta > 1000) return -1;
        mass += delta;
        weighted += delta * index;
        fingerprint = (fingerprint + delta * power_mod(base, index)) % MODULUS;
        if (fingerprint < 0) fingerprint += MODULUS;
    }
    if (mass == 0 || weighted % mass != 0) return 0;
    long index = weighted / mass;
    if (index < 0 || index >= n) return 0;
    long expected = mass * power_mod(base, index) % MODULUS;
    if (expected < 0) expected += MODULUS;
    return fingerprint == expected ? index + 1 : 0;
}
