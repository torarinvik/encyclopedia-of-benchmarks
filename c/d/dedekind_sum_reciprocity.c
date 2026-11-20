#include <stddef.h>
#include <stdint.h>

enum { DEDEKIND_MAX_MODULUS = 100000, DEDEKIND_MAX_LENGTH = 3 };
static const int64_t dedekind_offset = INT64_C(29999700001);

static int64_t dedekind_gcd(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int64_t dedekind_scaled(int64_t numerator, int64_t modulus) {
    if (modulus == 1) return 0;
    const int64_t tail = dedekind_scaled(modulus % numerator, numerator);
    const int64_t top = numerator * numerator + modulus * modulus + 1 -
                        3 * numerator * modulus - modulus * tail;
    return top / numerator;
}

int64_t dedekind_sum_reciprocity(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > DEDEKIND_MAX_LENGTH) return -1;
    const int64_t numerator = input[0];
    const int64_t modulus = input[1];
    if (length != 2 || modulus < 1 || modulus > DEDEKIND_MAX_MODULUS ||
        numerator < 0 || numerator >= modulus ||
        dedekind_gcd(numerator, modulus) != 1) return -1;
    const int64_t scaled = dedekind_scaled(numerator, modulus);
    return dedekind_offset + scaled;
}
