#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_LENGTH 2
#define MAX_N 8

static int64_t least_prime_factor(int64_t value) {
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return divisor;
    }
    return value;
}

static int64_t euclid_mullin_term(int64_t index) {
    int64_t product = 1;
    int64_t term = 1;
    for (int64_t position = 0; position < index; ++position) {
        term = least_prime_factor(product + 1);
        product *= term;
    }
    return term;
}

int64_t euclid_mullin_sequence(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_N) return -1;
    return euclid_mullin_term(input[0]);
}
