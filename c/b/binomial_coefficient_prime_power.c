#include <stddef.h>
#include <stdint.h>

enum {
    MAX_QUERIES = 32,
    MAX_N = 128,
    MAX_PARSEABLE = 68,
    MAX_OUTPUT_BYTES = 128
};

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor)
        if (value % divisor == 0) return 0;
    return 1;
}

static int64_t pow_mod(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

int64_t binomial_coefficient_prime_power(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE) return -1;
    const int64_t p = input[0], e = input[1], q_value = input[2];
    if (p < 2 || p > 31 || !is_prime(p) || e < 1 || e > 8 || q_value < 0 || q_value > MAX_QUERIES)
        return -1;
    int64_t modulus = 1;
    for (int64_t i = 0; i < e; ++i) {
        modulus *= p;
        if (modulus > 1000000000) return -1;
    }
    const size_t q = (size_t)q_value;
    if (length != 3 + 2 * q) return -1;
    for (size_t i = 0; i < q; ++i) {
        const int64_t n = input[3 + 2 * i], k = input[4 + 2 * i];
        if (n < 0 || n > MAX_N || k < 0 || k > n) return -1;
    }
    if (q == 0) return 0;
    const size_t required = 4 * q;
    if (output == NULL || capacity < required) return -2;

    int64_t unit_prefix[MAX_N + 1] = {0};
    int64_t p_free_factorial[MAX_N + 1] = {0};
    uint16_t valuation[MAX_N + 1] = {0};
    uint32_t residues[MAX_QUERIES] = {0};
    unit_prefix[0] = 1;
    p_free_factorial[0] = 1;
    for (size_t n = 1; n <= MAX_N; ++n) {
        const int64_t factor = n % (size_t)p == 0 ? 1 : (int64_t)n;
        unit_prefix[n] = unit_prefix[n - 1] * factor % modulus;
        p_free_factorial[n] = unit_prefix[n] * p_free_factorial[n / (size_t)p] % modulus;
        valuation[n] = (uint16_t)(n / (size_t)p + valuation[n / (size_t)p]);
    }

    const int64_t phi = modulus / p * (p - 1);
    for (size_t i = 0; i < q; ++i) {
        const size_t n = (size_t)input[3 + 2 * i], k = (size_t)input[4 + 2 * i];
        const size_t p_power = (size_t)valuation[n] - valuation[k] - valuation[n - k];
        if (p_power >= (size_t)e) {
            residues[i] = 0;
        } else {
            const int64_t denominator = p_free_factorial[k] * p_free_factorial[n - k] % modulus;
            const int64_t inverse = pow_mod(denominator, phi - 1, modulus);
            const int64_t prime_factor = pow_mod(p, (int64_t)p_power, modulus);
            residues[i] = (uint32_t)(p_free_factorial[n] * inverse % modulus * prime_factor % modulus);
        }
    }
    for (size_t i = 0; i < q; ++i)
        for (size_t byte = 0; byte < 4; ++byte)
            output[4 * i + byte] = (uint8_t)(residues[i] >> (8 * byte));
    return (int64_t)required;
}
