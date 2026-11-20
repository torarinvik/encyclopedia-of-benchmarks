module smallest_number_with_n_divisors;

const usz MAX_INPUT = 3;
const usz MAX_STACK = 128;
const usz PRIME_COUNT = 5;
const long MAX_DIVISOR_COUNT = 63;
const long MAX_LIMIT = 1000000;

fn long smallest_number_with_n_divisors(long* input, usz length) @export("smallest_number_with_n_divisors") {
    if (input == null || length < 2 || length > MAX_INPUT || length != 2) return -1;
    long divisor_count = input[0];
    long limit = input[1];
    if (divisor_count < 1 || divisor_count > MAX_DIVISOR_COUNT || limit < 1 || limit > MAX_LIMIT) return -1;

    long[PRIME_COUNT] primes = {2, 3, 5, 7, 11};
    long[MAX_STACK] remaining_stack = {};
    long[MAX_STACK] max_factor_stack = {};
    long[MAX_STACK] prime_index_stack = {};
    long[MAX_STACK] product_stack = {};
    usz top = 1;
    remaining_stack[0] = divisor_count;
    max_factor_stack[0] = divisor_count;
    product_stack[0] = 1;
    long best = limit + 1;

    while (top != 0) {
        top -= 1;
        long remaining = remaining_stack[top];
        long max_factor = max_factor_stack[top];
        long prime_index = prime_index_stack[top];
        long product = product_stack[top];
        if (remaining == 1) {
            if (product < best) best = product;
            continue;
        }
        if (prime_index >= (long)PRIME_COUNT) continue;
        long prime = primes[(usz)prime_index];
        long factor_limit = max_factor < remaining ? max_factor : remaining;
        for (long factor = 2; factor <= factor_limit; factor += 1) {
            if (remaining % factor != 0) continue;
            long candidate = product;
            bool valid = true;
            for (long step = 1; step < factor; step += 1) {
                if (candidate > limit / prime) { valid = false; break; }
                candidate *= prime;
            }
            if (valid && candidate < best) {
                if (top >= MAX_STACK) return -1;
                remaining_stack[top] = remaining / factor;
                max_factor_stack[top] = factor;
                prime_index_stack[top] = prime_index + 1;
                product_stack[top] = candidate;
                top += 1;
            }
        }
    }
    return best <= limit ? best : 0;
}
