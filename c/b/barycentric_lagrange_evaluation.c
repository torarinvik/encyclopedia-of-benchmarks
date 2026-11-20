#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_INPUT_LENGTH 19
#define MAX_NODES 8

static int64_t mod_pow(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

int64_t barycentric_lagrange_evaluation(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > MAX_NODES) return -1;
    const size_t count = (size_t)count_value;
    if (length != 2 * count + 2) return -1;

    for (size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    for (size_t left = 0; left < count; ++left)
        for (size_t right = 0; right < left; ++right)
            if (input[1 + left] == input[1 + right]) return -1;

    int64_t weights[MAX_NODES] = {0};
    for (size_t index = 0; index < count; ++index) {
        int64_t product = 1;
        const int64_t node = input[1 + index];
        for (size_t other = 0; other < count; ++other) {
            if (other == index) continue;
            const int64_t difference = (node - input[1 + other] + MODULUS) % MODULUS;
            product = product * difference % MODULUS;
        }
        weights[index] = mod_pow(product, MODULUS - 2);
    }

    const size_t ordinate_start = 1 + count;
    const int64_t query = input[2 * count + 1];
    for (size_t index = 0; index < count; ++index)
        if (query == input[1 + index]) return input[ordinate_start + index];

    int64_t numerator = 0;
    int64_t denominator = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t difference = (query - input[1 + index] + MODULUS) % MODULUS;
        const int64_t term = weights[index] * mod_pow(difference, MODULUS - 2) % MODULUS;
        numerator = (numerator + term * input[ordinate_start + index]) % MODULUS;
        denominator = (denominator + term) % MODULUS;
    }
    if (denominator == 0) return -1;
    return numerator * mod_pow(denominator, MODULUS - 2) % MODULUS;
}
