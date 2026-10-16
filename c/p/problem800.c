#include <math.h>
#include <stdint.h>
#include <stdlib.h>

static int is_composite(const uint64_t *bits, int64_t value)
{
    return (int)((bits[(uint64_t)value >> 6] >> ((uint64_t)value & 63)) & 1U);
}

static void mark_composite(uint64_t *bits, int64_t value)
{
    bits[(uint64_t)value >> 6] |= UINT64_C(1) << ((uint64_t)value & 63);
}

int64_t problem800(int64_t base, int64_t degree)
{
    if (base < 2 || base > 1000000 || degree < 1 || degree > 1000000) return -1;
    const double upper_bound = (double)degree * log2((double)base);
    const int64_t prime_limit = (int64_t)upper_bound;
    if (prime_limit <= 2) return 0;

    const uint64_t words = ((uint64_t)prime_limit + 63) / 64;
    uint64_t *composite = (uint64_t *)calloc(words, sizeof(uint64_t));
    if (composite == NULL) return -1;
    for (int64_t prime = 2; prime <= (prime_limit - 1) / prime; ++prime) {
        if (is_composite(composite, prime)) continue;
        for (int64_t multiple = prime * prime; multiple < prime_limit; multiple += prime)
            mark_composite(composite, multiple);
    }

    int64_t right_value = 0;
    int64_t prime_count = 0;
    for (int64_t value = 2; value < prime_limit; ++value) {
        if (!is_composite(composite, value)) { right_value = value; ++prime_count; }
    }
    if (prime_count < 2) { free(composite); return 0; }

    int64_t right_rank = prime_count - 1;
    int64_t left_rank = 0;
    int64_t left_value = 2;
    int64_t count = 0;
    while (left_rank < right_rank) {
        while (is_composite(composite, left_value)) ++left_value;
        const double left_log = log2((double)left_value);
        while ((double)right_value * left_log + (double)left_value * log2((double)right_value) > upper_bound) {
            --right_rank;
            --right_value;
            while (right_value >= 2 && is_composite(composite, right_value)) --right_value;
        }
        count += right_rank - left_rank;
        ++left_rank;
        ++left_value;
    }
    free(composite);
    return count;
}
