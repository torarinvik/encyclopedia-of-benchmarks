#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_INPUT = 26, MAX_Q = 4 * MAX_N * MAX_N };

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[offset + b] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t knapsack_profit_scaling_fptas(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    int64_t cap64 = input[0], n64 = input[1];
    if (cap64 < 1 || cap64 > 100 || n64 < 1 || n64 > MAX_N || length != 2 + 2 * (size_t)n64) return -1;
    size_t n = (size_t)n64;
    int64_t weight[MAX_N], profit[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        weight[i] = input[2 + 2 * i]; profit[i] = input[3 + 2 * i];
        if (weight[i] < 1 || weight[i] > 100 || profit[i] < 1 || profit[i] > 10000) return -1;
    }
    if (output == NULL || capacity < 16) return -2;
    int order[MAX_N];
    size_t eligible = 0;
    for (size_t i = 0; i < n; ++i) if (weight[i] <= cap64) order[eligible++] = (int)i;
    for (size_t i = 1; i < eligible; ++i) {
        int key = order[i]; size_t j = i;
        while (j > 0 && profit[key] * weight[order[j - 1]] > profit[order[j - 1]] * weight[key]) {
            order[j] = order[j - 1]; --j;
        }
        order[j] = key;
    }
    int64_t upper = 0, room = cap64;
    for (size_t k = 0; k < eligible; ++k) {
        int i = order[k];
        if (weight[i] <= room) { upper += profit[i]; room -= weight[i]; }
        else { upper += profit[i] * room / weight[i]; break; }
    }
    int64_t dp_weight[MAX_Q + 1], dp_mask[MAX_Q + 1];
    for (size_t q = 0; q <= MAX_Q; ++q) { dp_weight[q] = cap64 + 1; dp_mask[q] = 0; }
    dp_weight[0] = 0;
    size_t reachable = 0;
    if (upper > 0) for (size_t i = 0; i < n; ++i) {
        if (weight[i] > cap64) continue;
        size_t value = (size_t)(4 * (int64_t)n * profit[i] / upper);
        if (value == 0) continue;
        for (size_t q = reachable + 1; q > 0; --q) {
            size_t old = q - 1;
            if (dp_weight[old] > cap64) continue;
            size_t next = old + value;
            int64_t new_weight = dp_weight[old] + weight[i];
            int64_t new_mask = dp_mask[old] | ((int64_t)1 << i);
            if (new_weight < dp_weight[next] || (new_weight == dp_weight[next] && new_mask < dp_mask[next])) {
                dp_weight[next] = new_weight; dp_mask[next] = new_mask;
            }
        }
        reachable += value;
    }
    size_t best = 0;
    for (size_t q = 1; q <= MAX_Q; ++q) if (dp_weight[q] <= cap64) best = q;
    int64_t mask = dp_mask[best], value = 0;
    for (size_t i = 0; i < n; ++i) if (((uint64_t)mask >> i) & 1U) value += profit[i];
    store_i64_le(output, 0, mask); store_i64_le(output, 8, value);
    return 16;
}
