#include <stddef.h>
#include <stdint.h>

static int64_t integer_sqrt_i64(int64_t value, int64_t upper) {
    int64_t low = 0;
    int64_t high = upper + 1;
    while (low + 1 < high) {
        const int64_t middle = low + (high - low) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

int64_t fermat_factorization(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    const int64_t number = input[0];
    const int64_t max_steps = input[1];
    if (number < 3 || number > 1000000000000LL || number % 2 == 0
        || max_steps < 0 || max_steps > 4096) return -1;
    int64_t candidate = integer_sqrt_i64(number, 1000000);
    if (candidate * candidate < number) ++candidate;
    for (int64_t step = 0; step < max_steps; ++step, ++candidate) {
        const int64_t difference = candidate * candidate - number;
        const int64_t root = integer_sqrt_i64(difference, candidate);
        if (root * root == difference) {
            const int64_t factor = candidate - root;
            if (factor > 1 && factor < number) return factor;
        }
    }
    return 0;
}
