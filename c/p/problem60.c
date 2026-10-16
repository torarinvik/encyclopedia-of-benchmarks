/* Source-ordered concatenatable-prime search for Project Euler 60. */
#include <stdint.h>

enum { MAX_PRIMES = 1000, TARGET_SIZE = 5 };

static int is_prime(int64_t value)
{
    if (value < 2) return 0;
    if (value == 2 || value == 3) return 1;
    if (value % 2 == 0 || value % 3 == 0) return 0;
    for (int64_t divisor = 5; divisor <= value / divisor; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return 0;
    }
    return 1;
}

static int64_t concatenate(int64_t left, int64_t right)
{
    int64_t scale = 10;
    while (scale <= right) scale *= 10;
    return left * scale + right;
}

static int pair_works(int left_index, int right_index, const int *primes,
                      uint8_t *cache)
{
    const int key = left_index * MAX_PRIMES + right_index;
    if (cache[key] != 0) return cache[key] == 2;
    const int reverse_key = right_index * MAX_PRIMES + left_index;
    if (cache[reverse_key] != 0) return cache[reverse_key] == 2;
    const int64_t left = primes[left_index];
    const int64_t right = primes[right_index];
    const int result = is_prime(concatenate(left, right))
                    && is_prime(concatenate(right, left));
    cache[key] = cache[reverse_key] = result ? 2 : 1;
    return result;
}

static int64_t search_set(const int *primes, int prime_count, uint8_t *cache,
                          int *chain, int depth, int start, int64_t sum)
{
    if (depth == TARGET_SIZE) return sum;
    for (int index = start; index < prime_count; ++index) {
        int compatible = 1;
        for (int member = 0; member < depth; ++member) {
            if (!pair_works(index, chain[member], primes, cache)) {
                compatible = 0;
                break;
            }
        }
        if (!compatible) continue;
        chain[depth] = index;
        const int64_t result = search_set(primes, prime_count, cache, chain,
                                          depth + 1, index + 1, sum + primes[index]);
        if (result != 0) return result;
    }
    return 0;
}

int64_t problem60(int64_t placeholder)
{
    if (placeholder != 0) return -1;
    int primes[MAX_PRIMES] = {3, 7, 13, 19};
    uint8_t pair_cache[MAX_PRIMES * MAX_PRIMES] = {0};
    int chain[TARGET_SIZE] = {0};
    int prime_count = 4;
    while (prime_count < MAX_PRIMES) {
        int64_t candidate = primes[prime_count - 1] + 3;
        while (!is_prime(candidate)) candidate += 3;
        primes[prime_count++] = (int)candidate;
    }
    for (int start = 0; start < prime_count; ++start) {
        chain[0] = start;
        const int64_t result = search_set(primes, prime_count, pair_cache,
                                          chain, 1, start + 1, primes[start]);
        if (result != 0) return result;
    }
    return -1;
}
