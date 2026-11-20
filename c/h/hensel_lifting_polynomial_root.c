#include <stddef.h>
#include <stdint.h>

enum { HLR_MAX_DEGREE = 4, HLR_MAX_PRIME = 43, HLR_MAX_EXPONENT = 6,
       HLR_MAX_MODULUS = 100000, HLR_MAX_LENGTH = 10 };

static int64_t hlr_mod(int64_t value, int64_t modulus) {
    int64_t result = value % modulus;
    return result < 0 ? result + modulus : result;
}

static int hlr_is_prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor * divisor <= value; ++divisor)
        if (value % divisor == 0) return 0;
    return 1;
}

static int64_t hlr_eval(const int64_t *coefficients, int64_t degree,
                        int64_t x, int64_t modulus) {
    int64_t result = 0;
    for (int64_t i = degree; i >= 0; --i)
        result = hlr_mod(result * x + coefficients[i], modulus);
    return result;
}

static int64_t hlr_derivative(const int64_t *coefficients, int64_t degree,
                              int64_t x, int64_t prime) {
    int64_t result = 0;
    for (int64_t i = degree; i >= 1; --i)
        result = hlr_mod(result * x + i * coefficients[i], prime);
    return result;
}

int64_t hensel_lifting_polynomial_root(const int64_t *input, size_t length) {
    if (input == NULL || length < 6 || length > HLR_MAX_LENGTH) return -1;
    const int64_t degree = input[0], prime = input[1];
    const int64_t exponent = input[2], seed = input[3];
    if (degree < 1 || degree > HLR_MAX_DEGREE || prime < 2 || prime > HLR_MAX_PRIME ||
        exponent < 1 || exponent > HLR_MAX_EXPONENT || seed < 0 || seed >= prime ||
        length != (size_t)(degree + 5) || !hlr_is_prime(prime)) return -1;
    const int64_t *coefficients = input + 4;
    for (int64_t i = 0; i <= degree; ++i)
        if (coefficients[i] < -1000 || coefficients[i] > 1000) return -1;

    int64_t modulus = 1;
    for (int64_t i = 0; i < exponent; ++i) {
        if (modulus > HLR_MAX_MODULUS / prime) return -1;
        modulus *= prime;
    }
    if (hlr_eval(coefficients, degree, seed, prime) != 0) return -1;
    const int64_t derivative = hlr_derivative(coefficients, degree, seed, prime);
    if (derivative == 0) return -1;
    int64_t inverse = 0;
    for (int64_t candidate = 1; candidate < prime; ++candidate) {
        if (derivative * candidate % prime == 1) {
            inverse = candidate;
            break;
        }
    }
    if (inverse == 0) return -1;

    int64_t root = seed;
    int64_t power = prime;
    for (int64_t stage = 1; stage < exponent; ++stage) {
        const int64_t next_power = power * prime;
        const int64_t residue = hlr_eval(coefficients, degree, root, next_power);
        const int64_t quotient_digit = residue / power;
        const int64_t correction = hlr_mod(-quotient_digit * inverse, prime);
        root += correction * power;
        power = next_power;
    }
    return root;
}
