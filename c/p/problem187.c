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

int64_t problem187(int64_t max_number)
{
    if (max_number < 0 || max_number > 100000000) return -1;
    const int64_t prime_limit = max_number / 2;
    if (prime_limit <= 2) return 0;

    const uint64_t words = ((uint64_t)prime_limit + 63) / 64;
    uint64_t *composite = (uint64_t *)calloc(words, sizeof(uint64_t));
    if (composite == NULL) return -1;
    mark_composite(composite, 0);
    mark_composite(composite, 1);
    for (int64_t prime = 2; prime <= (prime_limit - 1) / prime; ++prime) {
        if (is_composite(composite, prime)) continue;
        for (int64_t multiple = prime * prime; multiple < prime_limit; multiple += prime)
            mark_composite(composite, multiple);
    }

    int64_t right_value = prime_limit - 1;
    while (right_value >= 2 && is_composite(composite, right_value)) --right_value;
    if (right_value < 2) { free(composite); return 0; }
    int64_t prime_count = 0;
    for (int64_t value = 2; value <= right_value; ++value)
        if (!is_composite(composite, value)) ++prime_count;

    int64_t right_rank = prime_count - 1;
    int64_t left_rank = 0;
    int64_t count = 0;
    for (int64_t left_value = 2; left_value <= right_value; ++left_value) {
        if (is_composite(composite, left_value)) continue;
        if (left_value > right_value) break;
        while (right_rank >= left_rank && left_value * right_value >= max_number) {
            --right_rank;
            --right_value;
            while (right_value >= 2 && is_composite(composite, right_value)) --right_value;
        }
        if (right_rank < left_rank) break;
        count += right_rank - left_rank + 1;
        ++left_rank;
    }
    free(composite);
    return count;
}
