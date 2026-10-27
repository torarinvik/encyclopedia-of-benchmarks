#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INPUT = 18, MAX_Q = 128 };

static void store_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[offset + b] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t knapsack_profit_scaling_small_large_fptas(const int64_t *input, size_t length,
                                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    int64_t cap = input[0], n64 = input[1];
    if (cap < 1 || cap > 30 || n64 < 1 || n64 > MAX_N || length != 2 + 2 * (size_t)n64) return -1;
    size_t n = (size_t)n64;
    int64_t w[MAX_N], p[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        w[i] = input[2 + 2 * i]; p[i] = input[3 + 2 * i];
        if (w[i] < 1 || w[i] > 30 || p[i] < 1 || p[i] > 100) return -1;
    }
    if (output == NULL || capacity < 16) return -2;

    int order[MAX_N]; size_t eligible = 0;
    for (size_t i = 0; i < n; ++i) if (w[i] <= cap) order[eligible++] = (int)i;
    for (size_t i = 1; i < eligible; ++i) {
        int key = order[i]; size_t j = i;
        while (j > 0 && p[key] * w[order[j - 1]] > p[order[j - 1]] * w[key]) {
            order[j] = order[j - 1]; --j;
        }
        order[j] = key;
    }
    int64_t upper_num = 0, upper_den = 1, room = cap;
    for (size_t k = 0; k < eligible; ++k) {
        int i = order[k];
        if (w[i] <= room) { upper_num += p[i]; room -= w[i]; }
        else { upper_num = upper_num * w[i] + p[i] * room; upper_den = w[i]; break; }
    }
    int small[MAX_N], ns = 0, large[MAX_N], nl = 0;
    for (size_t i = 0; i < n; ++i) if (w[i] <= cap) {
        if (4 * p[i] * upper_den <= upper_num) small[ns++] = (int)i; else large[nl++] = (int)i;
    }
    for (int i = 1; i < ns; ++i) {
        int key = small[i], j = i;
        while (j > 0 && p[key] * w[small[j - 1]] > p[small[j - 1]] * w[key]) { small[j] = small[j - 1]; --j; }
        small[j] = key;
    }
    int64_t dpw[MAX_Q + 1], dpm[MAX_Q + 1];
    for (size_t q = 0; q <= MAX_Q; ++q) { dpw[q] = cap + 1; dpm[q] = 0; }
    dpw[0] = 0; size_t reachable = 0;
    for (int k = 0; k < nl; ++k) {
        int i = large[k]; size_t value = upper_num ? (size_t)(16 * p[i] * upper_den / upper_num) : 0;
        for (size_t q = reachable + 1; q > 0; ) {
            --q;
            if (dpw[q] <= cap) {
                size_t dst = q + value; int64_t nw = dpw[q] + w[i], nm = dpm[q] | ((int64_t)1 << i);
                if (nw < dpw[dst] || (nw == dpw[dst] && nm < dpm[dst])) { dpw[dst] = nw; dpm[dst] = nm; }
            }
        }
        reachable += value;
    }
    int64_t best_mask = 0, best_profit = 0;
    for (size_t q = 0; q <= reachable; ++q) if (dpw[q] <= cap) {
        int64_t mask = dpm[q], value = 0, remaining = cap - dpw[q];
        for (size_t i = 0; i < n; ++i) if (((uint64_t)mask >> i) & 1U) value += p[i];
        for (int k = 0; k < ns; ++k) { int i = small[k]; if (w[i] <= remaining) { remaining -= w[i]; mask |= (int64_t)1 << i; value += p[i]; } }
        if (value > best_profit || (value == best_profit && mask < best_mask)) { best_profit = value; best_mask = mask; }
    }
    store_i64(output, 0, best_mask); store_i64(output, 8, best_profit);
    return 16;
}
