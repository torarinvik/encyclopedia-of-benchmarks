#include <stdint.h>
#include <stdlib.h>

#define MAX_LIMIT 50000000
#define MAX_PRIME_BOUND 7072

static int64_t integer_sqrt(int64_t value) { int64_t root = 0; while ((root + 1) * (root + 1) <= value) ++root; return root; }
int64_t problem87(int64_t limit)
{
    if (limit < 24 || limit > MAX_LIMIT) return -1;
    const int64_t bound = integer_sqrt(limit - 24) < 2 ? 2 : integer_sqrt(limit - 24);
    uint8_t is_prime[MAX_PRIME_BOUND] = {0};
    for (int64_t p = 2; p <= bound; ++p) is_prime[p] = 1;
    for (int64_t p = 2; p * p <= bound; ++p) if (is_prime[p])
        for (int64_t multiple = p * p; multiple <= bound; multiple += p) is_prime[multiple] = 0;
    const size_t byte_count = (size_t)(limit + 7) / 8;
    uint8_t *seen = (uint8_t *)calloc(byte_count, 1);
    if (seen == NULL) return -1;
    for (int64_t p1 = 2; p1 <= bound; ++p1) if (is_prime[p1]) {
        const int64_t square = p1 * p1;
        for (int64_t p2 = 2; p2 <= bound; ++p2) if (is_prime[p2]) {
            const int64_t cube = p2 * p2 * p2;
            if (square + cube >= limit - 16) break;
            for (int64_t p3 = 2; p3 <= bound; ++p3) if (is_prime[p3]) {
                const int64_t fourth = p3 * p3 * p3 * p3;
                const int64_t total = square + cube + fourth;
                if (total >= limit) break;
                seen[(size_t)total >> 3] |= (uint8_t)(1u << (total & 7));
            }
        }
    }
    int64_t count = 0;
    for (size_t i = 0; i < byte_count; ++i) for (uint8_t bits = seen[i]; bits != 0; bits &= (uint8_t)(bits - 1)) ++count;
    free(seen);
    return count;
}
