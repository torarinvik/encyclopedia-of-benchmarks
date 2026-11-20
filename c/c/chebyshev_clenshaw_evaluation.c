#include <stddef.h>
#include <stdint.h>

enum { MODULUS = 998244353, MAX_DEGREE = 16, MAX_PARSEABLE_LENGTH = 21 };

static int64_t reduce_field(int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

int64_t chebyshev_clenshaw_evaluation(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t degree_value = input[0];
    if (degree_value < 0 || degree_value > MAX_DEGREE) return -1;
    const size_t degree = (size_t)degree_value;
    if (length != degree + 3) return -1;
    const int64_t x = input[1];
    if (x < 0 || x >= MODULUS) return -1;
    for (size_t i = 0; i <= degree; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= MODULUS) return -1;

    const int64_t twice_x = (2 * x) % MODULUS;
    int64_t next_one = 0;
    int64_t next_two = 0;
    for (size_t k = degree; k > 0; --k) {
        const int64_t current = reduce_field(input[2 + k] + twice_x * next_one - next_two);
        next_two = next_one;
        next_one = current;
    }
    return reduce_field(input[2] + x * next_one - next_two);
}
