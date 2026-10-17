#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 11
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define I64_RESULT_MASK UINT64_C(0x7fffffffffffffff)

static void fnv_byte(uint64_t *hash, uint8_t value)
{
    *hash = (*hash ^ (uint64_t)value) * FNV_PRIME;
}

/* Iterate the source's lexicographic, prefix-sum-pruned backtracking tree. */
static uint32_t enumerate(uint8_t n, uint64_t *hash, bool hash_rows)
{
    if (n == 0) return 1;

    uint8_t vector[MAX_N] = {0};
    uint8_t frequencies[MAX_N] = {0};
    uint8_t next_candidate[MAX_N] = {0};
    uint8_t prefix_sum[MAX_N + 1] = {0};
    size_t depth = 0;
    uint32_t solution_count = 0;

    for (;;) {
        if (depth == n) {
            bool is_magic = true;
            for (size_t symbol = 0; symbol < n; ++symbol) {
                if (frequencies[symbol] != vector[symbol]) {
                    is_magic = false;
                    break;
                }
            }
            if (is_magic) {
                ++solution_count;
                if (hash_rows) {
                    for (size_t index = 0; index < n; ++index) {
                        fnv_byte(hash, vector[index]);
                    }
                }
            }
            --depth;
            --frequencies[vector[depth]];
            continue;
        }

        const uint8_t candidate = next_candidate[depth];
        if (candidate >= n) {
            next_candidate[depth] = 0;
            if (depth == 0) break;
            --depth;
            --frequencies[vector[depth]];
            continue;
        }
        next_candidate[depth] = (uint8_t)(candidate + 1);
        const uint8_t sum = (uint8_t)(prefix_sum[depth] + candidate);
        if (sum > n) continue;

        vector[depth] = candidate;
        ++frequencies[candidate];
        prefix_sum[depth + 1] = sum;
        ++depth;
        next_candidate[depth] = 0;
    }
    return solution_count;
}

int64_t magic_sequence(const int64_t *input, size_t length)
{
    if (input == NULL || length != 1 || input[0] < 0 || input[0] > MAX_N) return -1;
    const uint8_t n = (uint8_t)input[0];

    uint64_t hash = FNV_OFFSET_BASIS;
    fnv_byte(&hash, n);
    const uint32_t solution_count = enumerate(n, &hash, false);
    for (unsigned int shift = 0; shift < 32; shift += 8) {
        fnv_byte(&hash, (uint8_t)(solution_count >> shift));
    }
    (void)enumerate(n, &hash, true);
    return (int64_t)(hash & I64_RESULT_MASK);
}
