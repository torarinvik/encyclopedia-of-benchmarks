#include <stdint.h>

#define MAX_N INT64_C(1000000000)
#define BASE_LIMIT 100000
#define MAX_CACHE (MAX_N / BASE_LIMIT + 2)
#define MODULUS INT64_C(998244353)

static int64_t triangular_mod(int64_t n) {
    int64_t left = n;
    int64_t right = n + 1;
    if ((left & 1) == 0) left /= 2;
    else right /= 2;
    return ((left % MODULUS) * (right % MODULUS)) % MODULUS;
}

static int64_t summatory_phi(int64_t value, int64_t total_n,
                             const int64_t *prefix, int64_t *memo,
                             uint8_t *visited) {
    if (value <= BASE_LIMIT) return prefix[value];
    const int64_t cache_index = total_n / value;
    if (visited[cache_index]) return memo[cache_index];

    int64_t answer = triangular_mod(value);
    int64_t left = 2;
    while (left <= value) {
        const int64_t quotient = value / left;
        const int64_t right = value / quotient;
        const int64_t block_size = right - left + 1;
        const int64_t sub_sum = summatory_phi(quotient, total_n, prefix, memo, visited);
        const int64_t contribution = ((block_size % MODULUS) * sub_sum) % MODULUS;
        answer = (answer - contribution + MODULUS) % MODULUS;
        left = right + 1;
    }
    visited[cache_index] = 1;
    memo[cache_index] = answer;
    return answer;
}

int64_t sum_of_totient_function(int64_t n) {
    if (n < 1 || n > MAX_N) return -1;
    int64_t prefix[BASE_LIMIT + 1];
    for (int64_t value = 0; value <= BASE_LIMIT; ++value) prefix[value] = value;
    const int64_t sieve_limit = n < BASE_LIMIT ? n : BASE_LIMIT;
    for (int64_t prime = 2; prime <= sieve_limit; ++prime) {
        if (prefix[prime] != prime) continue;
        for (int64_t multiple = prime; multiple <= sieve_limit; multiple += prime)
            prefix[multiple] -= prefix[multiple] / prime;
    }
    int64_t running = 0;
    for (int64_t value = 1; value <= sieve_limit; ++value) {
        running = (running + prefix[value]) % MODULUS;
        prefix[value] = running;
    }
    if (n <= BASE_LIMIT) return prefix[n];

    int64_t memo[MAX_CACHE] = {0};
    uint8_t visited[MAX_CACHE] = {0};
    return summatory_phi(n, n, prefix, memo, visited);
}
