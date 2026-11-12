#include <stddef.h>
#include <stdint.h>

#define MAX_T 8
#define MAX_K INT64_C(1000000000)
#define MAX_P INT64_C(1000)

static int64_t modular_power(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1 % modulus;
    base %= modulus;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor * divisor <= value; ++divisor)
        if (value % divisor == 0) return 0;
    return 1;
}

static size_t factor_distinct(int64_t value, int64_t *factors) {
    size_t count = 0;
    for (int64_t divisor = 2; divisor * divisor <= value; ++divisor) {
        if (value % divisor != 0) continue;
        factors[count++] = divisor;
        do value /= divisor; while (value % divisor == 0);
    }
    if (value > 1) factors[count++] = value;
    return count;
}

static int64_t primitive_root(int64_t prime) {
    if (prime == 2) return 1;
    const int64_t order = prime - 1;
    int64_t factors[16];
    const size_t count = factor_distinct(order, factors);
    for (int64_t candidate = 2; candidate < prime; ++candidate) {
        size_t i = 0;
        while (i < count && modular_power(candidate, order / factors[i], prime) != 1) ++i;
        if (i == count) return candidate;
    }
    return -1;
}

static int64_t gcd_i64(int64_t a, int64_t b) {
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static int64_t modular_inverse(int64_t value, int64_t modulus) {
    int64_t old_t = 0, new_t = 1;
    int64_t old_r = modulus, new_r = value % modulus;
    while (new_r != 0) {
        const int64_t quotient = old_r / new_r;
        const int64_t next_t = old_t - quotient * new_t;
        const int64_t next_r = old_r - quotient * new_r;
        old_t = new_t;
        new_t = next_t;
        old_r = new_r;
        new_r = next_r;
    }
    if (old_t < 0) old_t += modulus;
    return old_t;
}

static int64_t kth_root(int64_t exponent, int64_t residue, int64_t prime) {
    if (exponent == 0) return residue == 1 ? 0 : -1;
    if (residue == 0) return 0;
    const int64_t order = prime - 1;
    const int64_t generator = primitive_root(prime);
    int64_t power = 1, discrete_log = -1;
    for (int64_t candidate = 0; candidate < order; ++candidate) {
        if (power == residue) {
            discrete_log = candidate;
            break;
        }
        power = power * generator % prime;
    }
    if (discrete_log < 0) return -1;

    const int64_t common = gcd_i64(exponent, order);
    if (discrete_log % common != 0) return -1;
    const int64_t reduced_order = order / common;
    int64_t root_exponent = 0;
    if (reduced_order > 1) {
        const int64_t inverse = modular_inverse((exponent / common) % reduced_order,
                                                reduced_order);
        root_exponent = (discrete_log / common) * inverse % reduced_order;
    }
    const int64_t root = modular_power(generator, root_exponent, prime);
    return modular_power(root, exponent, prime) == residue ? root : -1;
}

int64_t kth_root_mod(const int64_t *input, size_t length,
                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > 1 + 3 * MAX_T) return -1;
    const int64_t t64 = input[0];
    if (t64 < 1 || t64 > MAX_T) return -1;
    const size_t t = (size_t)t64;
    if (length != 1 + 3 * t) return -1;

    int64_t triples[3 * MAX_T] = {0};
    for (size_t i = 0; i < 3 * t; i += 3) {
        const int64_t exponent = input[i + 1], residue = input[i + 2], prime = input[i + 3];
        if (exponent < 0 || exponent > MAX_K || prime < 2 || prime > MAX_P ||
            residue < 0 || residue >= prime || !is_prime(prime)) return -1;
        triples[i] = exponent;
        triples[i + 1] = residue;
        triples[i + 2] = prime;
    }
    const size_t required = 8 * t;
    if (output == NULL || capacity < required) return -2;

    for (size_t test = 0; test < t; ++test) {
        const int64_t root = kth_root(triples[3 * test], triples[3 * test + 1], triples[3 * test + 2]);
        const uint64_t bits = (uint64_t)root;
        for (size_t byte = 0; byte < 8; ++byte)
            output[8 * test + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)required;
}
