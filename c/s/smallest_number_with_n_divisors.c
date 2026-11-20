#include <stddef.h>
#include <stdint.h>

enum { MAX_INPUT = 3, MAX_STACK = 128, MAX_DIVISOR_COUNT = 63,
       MAX_LIMIT = 1000000, PRIME_COUNT = 5 };

int64_t smallest_number_with_n_divisors(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (length != 2) return -1;
    const int64_t divisor_count = input[0], limit = input[1];
    if (divisor_count < 1 || divisor_count > MAX_DIVISOR_COUNT ||
        limit < 1 || limit > MAX_LIMIT) return -1;

    static const int64_t primes[PRIME_COUNT] = {2, 3, 5, 7, 11};
    int64_t remaining_stack[MAX_STACK];
    int64_t max_factor_stack[MAX_STACK];
    int64_t prime_index_stack[MAX_STACK];
    int64_t product_stack[MAX_STACK];
    size_t top = 1;
    remaining_stack[0] = divisor_count;
    max_factor_stack[0] = divisor_count;
    prime_index_stack[0] = 0;
    product_stack[0] = 1;
    int64_t best = limit + 1;

    while (top != 0) {
        --top;
        const int64_t remaining = remaining_stack[top];
        const int64_t max_factor = max_factor_stack[top];
        const int64_t prime_index = prime_index_stack[top];
        const int64_t product = product_stack[top];
        if (remaining == 1) {
            if (product < best) best = product;
            continue;
        }
        if (prime_index >= PRIME_COUNT) continue;
        const int64_t prime = primes[prime_index];
        const int64_t factor_limit = max_factor < remaining ? max_factor : remaining;
        for (int64_t factor = 2; factor <= factor_limit; ++factor) {
            if (remaining % factor != 0) continue;
            int64_t candidate = product;
            int valid = 1;
            for (int64_t exponent_step = 1; exponent_step < factor; ++exponent_step) {
                if (candidate > limit / prime) {
                    valid = 0;
                    break;
                }
                candidate *= prime;
            }
            if (valid && candidate < best) {
                if (top >= MAX_STACK) return -1;
                remaining_stack[top] = remaining / factor;
                max_factor_stack[top] = factor;
                prime_index_stack[top] = prime_index + 1;
                product_stack[top] = candidate;
                ++top;
            }
        }
    }
    return best <= limit ? best : 0;
}
