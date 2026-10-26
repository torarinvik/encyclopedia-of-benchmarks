#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 16, MAX_INPUT = 34, MAX_OUTPUT = 136 };

static void put64(uint8_t *output, size_t position, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = (uint8_t)(bits >> (8u * byte));
}

static size_t bit_count(uint64_t value)
{
    size_t count = 0;
    while (value != 0) { value &= value - 1u; ++count; }
    return count;
}

int64_t weighted_greedy_set_cover(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 4u || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 1 || m64 > MAX_M ||
        length != 2u + 2u * (size_t)m64) return -1;
    size_t n = (size_t)n64, m = (size_t)m64;
    uint64_t full = (UINT64_C(1) << n) - 1u, union_mask = 0;
    int64_t weight[MAX_M];
    uint64_t mask[MAX_M];
    for (size_t set = 0; set < m; ++set) {
        weight[set] = input[2u + set];
        int64_t mask_value = input[2u + m + set];
        if (weight[set] < 0 || weight[set] > 10000 || mask_value < 0 ||
            ((uint64_t)mask_value & ~full) != 0) return -1;
        mask[set] = (uint64_t)mask_value;
        union_mask |= mask[set];
    }
    if (union_mask != full) return -1;

    uint64_t covered = 0;
    size_t selected[MAX_M], selected_count = 0;
    while (covered != full) {
        size_t best = MAX_M, best_gain = 0;
        for (size_t set = 0; set < m; ++set) {
            size_t gain = bit_count(mask[set] & ~covered);
            if (gain == 0) continue;
            if (best == MAX_M || weight[set] * (int64_t)best_gain <
                weight[best] * (int64_t)gain) {
                best = set;
                best_gain = gain;
            }
        }
        if (best == MAX_M) return -1;
        selected[selected_count++] = best;
        covered |= mask[best];
    }

    size_t output_bytes = 8u * (selected_count + 1u);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT];
    put64(staged, 0, (int64_t)selected_count);
    for (size_t index = 0; index < selected_count; ++index)
        put64(staged, 8u * (index + 1u), (int64_t)selected[index]);
    for (size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return (int64_t)output_bytes;
}
