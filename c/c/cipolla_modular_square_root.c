#include <stddef.h>
#include <stdint.h>

#define MAX_PRIME INT64_C(1000003)

typedef struct {
    int64_t real;
    int64_t radical;
} extension_value;

static int64_t mod_pow(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    base %= modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

static int legendre_symbol(int64_t value, int64_t prime) {
    const int64_t symbol = mod_pow(value % prime, (prime - 1) / 2, prime);
    return symbol == prime - 1 ? -1 : (int)symbol;
}

static extension_value multiply(extension_value left, extension_value right,
                                int64_t radicand, int64_t prime) {
    const int64_t real = (left.real * right.real +
                          radicand * left.radical * right.radical) % prime;
    const int64_t radical = (left.real * right.radical +
                             left.radical * right.real) % prime;
    return (extension_value){real, radical};
}

static extension_value extension_pow(extension_value base, int64_t exponent,
                                     int64_t radicand, int64_t prime) {
    extension_value result = {1, 0};
    while (exponent > 0) {
        if ((exponent & 1) != 0)
            result = multiply(result, base, radicand, prime);
        base = multiply(base, base, radicand, prime);
        exponent >>= 1;
    }
    return result;
}

int64_t cipolla_modular_square_root(const int64_t *packed, size_t length) {
    if (packed == NULL || length != 2) return -1;
    const int64_t residue = packed[0], prime = packed[1];
    if (prime < 3 || prime > MAX_PRIME || (prime & 1) == 0 ||
        residue < 0 || residue >= prime) return -1;
    if (residue == 0) return 0;
    if (legendre_symbol(residue, prime) != 1) return -1;

    for (int64_t parameter = 0; parameter < prime; ++parameter) {
        int64_t radicand = (parameter * parameter - residue) % prime;
        if (radicand < 0) radicand += prime;
        if (legendre_symbol(radicand, prime) == -1) {
            const extension_value root = extension_pow(
                (extension_value){parameter, 1}, (prime + 1) / 2,
                radicand, prime);
            if (root.radical != 0) return -1;
            return root.real < prime - root.real ? root.real : prime - root.real;
        }
    }
    return -1;
}
