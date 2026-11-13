#include <stddef.h>
#include <stdint.h>

static int64_t power_mod(int64_t base, int64_t exponent) {
    const int64_t modulus = 1000000007;
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

int64_t turnstile_one_sparse_fingerprint_recovery(const int64_t *input, size_t length) {
    const int64_t modulus = 1000000007;
    if (input == NULL || length < 3 || length > 260) return -1;
    int64_t n = input[0], q = input[1], base = input[2];
    if (n < 1 || n > 64 || q < 0 || q > 128 || base < 1 || base >= modulus ||
        length != (size_t)(3 + 2 * q)) return -1;
    int64_t mass = 0, weighted = 0, fingerprint = 0;
    for (int64_t i = 0; i < q; ++i) {
        int64_t index = input[3 + 2 * i], delta = input[4 + 2 * i];
        if (index < 0 || index >= n || delta < -1000 || delta > 1000) return -1;
        mass += delta;
        weighted += delta * index;
        fingerprint = (fingerprint + delta * power_mod(base, index)) % modulus;
        if (fingerprint < 0) fingerprint += modulus;
    }
    if (mass == 0 || weighted % mass != 0) return 0;
    int64_t index = weighted / mass;
    if (index < 0 || index >= n) return 0;
    int64_t expected = (mass * power_mod(base, index)) % modulus;
    if (expected < 0) expected += modulus;
    return fingerprint == expected ? index + 1 : 0;
}
