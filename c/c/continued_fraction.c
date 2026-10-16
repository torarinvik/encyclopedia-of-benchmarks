#include <stddef.h>
#include <stdint.h>

#define MAX_COEFFICIENTS 32

static int64_t gcd_positive(int64_t left, int64_t right) {
    while (right != 0) {
        int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t continued_fraction(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity) {
    if (input == NULL || length != 2) return -1;
    int64_t numerator = input[0], denominator = input[1];
    if (numerator < -1000000 || numerator > 1000000 ||
        denominator < -1000000 || denominator > 1000000 || denominator == 0) return -1;
    int64_t divisor = gcd_positive(numerator < 0 ? -numerator : numerator,
                                   denominator < 0 ? -denominator : denominator);
    numerator /= divisor;
    denominator /= divisor;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }

    int64_t coefficients[MAX_COEFFICIENTS];
    size_t count = 0;
    while (1) {
        int64_t quotient = numerator / denominator;
        int64_t remainder = numerator % denominator;
        if (remainder < 0) { --quotient; remainder += denominator; }
        if (count == MAX_COEFFICIENTS) return -1;
        coefficients[count++] = quotient;
        if (remainder == 0) break;
        numerator = denominator;
        denominator = remainder;
    }
    size_t bytes = count * 8;
    if (bytes > capacity || output == NULL) return -2;
    for (size_t i = 0; i < count; ++i) {
        uint64_t bits = (uint64_t)coefficients[i];
        for (size_t byte = 0; byte < 8; ++byte)
            output[i * 8 + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)bytes;
}
