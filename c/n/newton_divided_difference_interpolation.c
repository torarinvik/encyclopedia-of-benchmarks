#include <stddef.h>
#include <stdint.h>

enum { MODULUS = 998244353, MAX_NODES = 12, MAX_LENGTH = 27 };

static int64_t mod_pow(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = (result * base) % MODULUS;
        base = (base * base) % MODULUS;
        exponent >>= 1;
    }
    return result;
}

int64_t newton_divided_difference_interpolation(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_NODES) return -1;
    const size_t count = (size_t)count_value;
    if (length != 2 + 2 * count) return -1;
    int64_t nodes[MAX_NODES], differences[MAX_NODES];
    for (size_t i = 0; i < count; ++i) {
        nodes[i] = input[1 + i];
        differences[i] = input[1 + count + i];
        if (nodes[i] < 0 || nodes[i] >= MODULUS || differences[i] < 0 || differences[i] >= MODULUS) return -1;
        for (size_t j = 0; j < i; ++j) if (nodes[i] == nodes[j]) return -1;
    }
    const int64_t query = input[length - 1];
    if (query < 0 || query >= MODULUS) return -1;

    for (size_t order = 1; order < count; ++order) {
        for (size_t i = count; i-- > order;) {
            int64_t numerator = differences[i] - differences[i - 1];
            if (numerator < 0) numerator += MODULUS;
            int64_t denominator = nodes[i] - nodes[i - order];
            if (denominator < 0) denominator += MODULUS;
            differences[i] = (numerator * mod_pow(denominator, MODULUS - 2)) % MODULUS;
        }
    }
    int64_t result = differences[count - 1];
    for (size_t i = count - 1; i-- > 0;) {
        int64_t factor = query - nodes[i];
        if (factor < 0) factor += MODULUS;
        result = (result * factor + differences[i]) % MODULUS;
    }
    return result;
}
