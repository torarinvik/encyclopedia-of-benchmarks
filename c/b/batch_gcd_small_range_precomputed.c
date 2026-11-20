#include <stddef.h>
#include <stdint.h>

#define MAX_VALUE 64
#define MAX_SMALL 8
#define MAX_QUERIES 64
#define MAX_INPUT_LENGTH (2 + 2 * MAX_QUERIES)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t batch_gcd_small_range_precomputed(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH + 1) return -1;
    const int64_t limit_value = input[0], query_value = input[1];
    if (limit_value < 1 || limit_value > MAX_VALUE || query_value < 0 ||
        query_value > MAX_QUERIES) return -1;
    const size_t limit = (size_t)limit_value;
    const size_t queries = (size_t)query_value;
    if (length != 2 + 2 * queries) return -1;
    for (size_t query = 0; query < queries; ++query) {
        const int64_t left = input[2 + 2 * query];
        const int64_t right = input[3 + 2 * query];
        if (left < 0 || left > limit_value || right < 0 || right > limit_value)
            return -1;
    }

    const size_t required = 8 * queries;
    if (output == NULL || capacity < required) return -2;

    size_t least[MAX_VALUE + 1] = {0};
    size_t primes[MAX_VALUE + 1] = {0};
    size_t prime_count = 0;
    for (size_t value = 2; value <= limit; ++value) {
        if (least[value] == 0) {
            least[value] = value;
            primes[prime_count++] = value;
        }
        for (size_t index = 0; index < prime_count; ++index) {
            const size_t prime = primes[index];
            const size_t composite = value * prime;
            if (composite > limit || prime > least[value]) break;
            least[composite] = prime;
        }
    }

    size_t factors[MAX_VALUE + 1][3] = {{0}};
    factors[1][0] = factors[1][1] = factors[1][2] = 1;
    for (size_t value = 2; value <= limit; ++value) {
        const size_t prime = least[value];
        const size_t quotient = value / prime;
        size_t a = factors[quotient][0] * prime;
        size_t b = factors[quotient][1];
        size_t c = factors[quotient][2];
        if (a > b) { const size_t t = a; a = b; b = t; }
        if (b > c) { const size_t t = b; b = c; c = t; }
        if (a > b) { const size_t t = a; a = b; b = t; }
        factors[value][0] = a;
        factors[value][1] = b;
        factors[value][2] = c;
    }

    size_t small_limit = 1;
    while ((small_limit + 1) * (small_limit + 1) <= limit) ++small_limit;
    size_t gcd_table[MAX_SMALL + 1][MAX_SMALL + 1] = {{0}};
    for (size_t left = 1; left <= small_limit; ++left) {
        gcd_table[left][0] = left;
        for (size_t right = 1; right < left; ++right)
            gcd_table[left][right] = gcd_table[right][left % right];
    }

    for (size_t query = 0; query < queries; ++query) {
        const size_t left = (size_t)input[2 + 2 * query];
        size_t remaining = (size_t)input[3 + 2 * query];
        size_t result = 0;
        if (left == 0) {
            result = remaining;
        } else {
            result = 1;
            for (size_t part = 0; part < 3; ++part) {
                const size_t factor = factors[left][part];
                const size_t common = factor <= small_limit
                    ? gcd_table[factor][remaining % factor]
                    : (remaining % factor == 0 ? factor : 1);
                remaining /= common;
                result *= common;
            }
        }
        store_i64_le(output, 8 * query, (int64_t)result);
    }
    return (int64_t)required;
}
