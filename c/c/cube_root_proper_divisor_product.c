#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 2
#define MAX_K 50000
#define MAX_VALUE 600000

static void build_prime_prefix(uint32_t *prefix) {
    prefix[0] = 0;
    prefix[1] = 0;
    for (uint32_t value = 2; value <= MAX_VALUE; ++value) prefix[value] = 1;
    for (uint32_t prime = 2; prime <= MAX_VALUE / prime; ++prime) {
        if (prefix[prime] != 0) {
            for (uint32_t multiple = prime * prime; multiple <= MAX_VALUE; multiple += prime)
                prefix[multiple] = 0;
        }
    }
    for (uint32_t value = 1; value <= MAX_VALUE; ++value)
        prefix[value] += prefix[value - 1];
}

static int is_prime(uint32_t value, const uint32_t *prefix) {
    return value >= 2 && prefix[value] - prefix[value - 1] == 1;
}

static int64_t count_tau_eight(uint32_t limit, const uint32_t *prefix) {
    int64_t count = 0;
    for (uint64_t prime = 2;; ++prime) {
        uint64_t power = 1;
        for (int exponent = 0; exponent < 7; ++exponent) {
            if (power > limit / prime) { power = (uint64_t)limit + 1; break; }
            power *= prime;
        }
        if (power > limit) break;
        if (is_prime((uint32_t)prime, prefix)) ++count;
    }

    for (uint64_t prime = 2;; ++prime) {
        const uint64_t cube = prime * prime * prime;
        if (cube > limit) break;
        if (is_prime((uint32_t)prime, prefix)) {
            const uint32_t q_max = (uint32_t)(limit / cube);
            count += prefix[q_max];
            if (prime <= q_max) --count;
        }
    }

    for (uint64_t prime = 2; prime * prime * prime < limit; ++prime) {
        if (!is_prime((uint32_t)prime, prefix)) continue;
        for (uint64_t other = prime + 1;; ++other) {
            if (prime > limit / other) break;
            const uint64_t product = prime * other;
            const uint32_t last_prime = (uint32_t)(limit / product);
            if (last_prime <= other) break;
            if (is_prime((uint32_t)other, prefix))
                count += prefix[last_prime] - prefix[(uint32_t)other];
        }
    }
    return count;
}

int64_t cube_root_proper_divisor_product(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (length != 1 || input[0] < 1 || input[0] > MAX_K) return -1;
    if (input[0] == 1) return 1;

    uint32_t prime_prefix[MAX_VALUE + 1];
    build_prime_prefix(prime_prefix);
    const int64_t target = input[0] - 1;
    if (count_tau_eight(MAX_VALUE, prime_prefix) < target) return -1;
    uint32_t low = 1;
    uint32_t high = MAX_VALUE;
    while (low < high) {
        const uint32_t middle = low + (high - low) / 2;
        if (count_tau_eight(middle, prime_prefix) >= target) high = middle;
        else low = middle + 1;
    }
    return low;
}
