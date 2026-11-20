#include <stddef.h>
#include <stdint.h>

enum { JACOBI_MAX_MODULUS = 1000000000, JACOBI_MAX_LENGTH = 3 };

static int64_t jacobi_reciprocity(int64_t numerator, int64_t denominator) {
    int64_t sign = 1;
    while (numerator != 0) {
        while ((numerator & 1) == 0) {
            numerator /= 2;
            if (denominator % 8 == 3 || denominator % 8 == 5) sign = -sign;
        }
        if (numerator % 4 == 3 && denominator % 4 == 3) sign = -sign;
        const int64_t old_numerator = numerator;
        numerator = denominator;
        denominator = old_numerator;
        numerator %= denominator;
    }
    return denominator == 1 ? sign : 0;
}

int64_t jacobi_symbol(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > JACOBI_MAX_LENGTH) return -1;
    const int64_t numerator = input[0];
    const int64_t denominator = input[1];
    if (denominator < 1 || denominator > JACOBI_MAX_MODULUS || (denominator & 1) == 0 ||
        numerator < 0 || numerator >= denominator || length != 2) return -1;
    return jacobi_reciprocity(numerator, denominator) + 1;
}
