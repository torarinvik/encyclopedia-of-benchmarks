#include <stddef.h>
#include <stdint.h>

#define MAX_N 4
#define MAX_F 3
#define MAX_Q 4
#define MAX_P 7
#define MAX_VALID 67
#define MAX_PARSEABLE 68
#define NEG_INF (INT64_MIN / 4)

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[at + i] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t capacitated_facility_location_t_hunt(const int64_t *in, size_t len,
                                             uint8_t *out, size_t cap) {
    if (in == NULL || len < 4 || len > MAX_PARSEABLE) return -1;
    int64_t nr = in[0], fr = in[1], qr = in[2], tr = in[3];
    if (nr < 1 || nr > MAX_N || fr < 1 || fr > MAX_F || qr < 1 || qr > MAX_Q
        || tr < 0 || tr >= fr) return -1;
    size_t n = (size_t)nr, f = (size_t)fr, qcopies = (size_t)qr, target = (size_t)tr;
    size_t points = n + f;
    if (len != 4 + points * points + 2 * f + qcopies + n) return -1;
    int64_t d[MAX_P][MAX_P] = {{0}}, fee[MAX_F] = {0}, capv[MAX_F] = {0};
    int64_t type[MAX_Q] = {0}, assigned[MAX_N] = {0};
    size_t pos = 4;
    for (size_t i = 0; i < points; ++i) for (size_t j = 0; j < points; ++j) {
        int64_t v = in[pos++]; if (v < 0 || v > 1000) return -1; d[i][j] = v;
    }
    for (size_t i = 0; i < points; ++i) {
        if (d[i][i] != 0) return -1;
        for (size_t j = 0; j < points; ++j) {
            if (i != j && d[i][j] == 0) return -1;
            if (d[i][j] != d[j][i]) return -1;
            for (size_t k = 0; k < points; ++k)
                if (d[i][j] > d[i][k] + d[k][j]) return -1;
        }
    }
    for (size_t i = 0; i < f; ++i) { fee[i] = in[pos++]; if (fee[i] < 0 || fee[i] > 1000) return -1; }
    for (size_t i = 0; i < f; ++i) { capv[i] = in[pos++]; if (capv[i] < 1 || capv[i] > nr) return -1; }
    for (size_t i = 0; i < qcopies; ++i) { type[i] = in[pos++]; if (type[i] < 0 || type[i] >= fr) return -1; }
    for (size_t i = 0; i < n; ++i) { assigned[i] = in[pos++]; if (assigned[i] < 0 || assigned[i] >= qr) return -1; }

    int64_t weight[MAX_Q] = {0}, profit[MAX_Q] = {0};
    int64_t old_cost = 0;
    for (size_t c = 0; c < qcopies; ++c) { profit[c] = fee[type[c]]; old_cost += fee[type[c]]; }
    for (size_t u = 0; u < n; ++u) {
        size_t c = (size_t)assigned[u], source = (size_t)type[c];
        if (++weight[c] > capv[source]) return -1;
        int64_t before = d[u][n + source], after = d[u][n + target];
        old_cost += before; profit[c] -= after - before;
    }

    int64_t result[5] = {0, 0, 0, old_cost, old_cost};
    for (size_t copies = 1; copies <= n; ++copies) {
        size_t limit = copies * (size_t)capv[target]; if (limit > n) limit = n;
        int64_t dp[MAX_N + 1], next_dp[MAX_N + 1];
        uint32_t masks[MAX_N + 1], next_masks[MAX_N + 1];
        for (size_t w = 0; w <= limit; ++w) { dp[w] = NEG_INF; masks[w] = 0; }
        dp[0] = 0;
        for (size_t item = 0; item < qcopies; ++item) {
            for (size_t w = 0; w <= limit; ++w) { next_dp[w] = dp[w]; next_masks[w] = masks[w]; }
            size_t iw = (size_t)weight[item];
            if (iw <= limit) for (size_t w = 0; w + iw <= limit; ++w) if (dp[w] != NEG_INF) {
                size_t nw = w + iw; int64_t value = dp[w] + profit[item];
                uint32_t mask = masks[w] | (UINT32_C(1) << item);
                if (value > next_dp[nw] || (value == next_dp[nw] && mask < next_masks[nw])) {
                    next_dp[nw] = value; next_masks[nw] = mask;
                }
            }
            for (size_t w = 0; w <= limit; ++w) { dp[w] = next_dp[w]; masks[w] = next_masks[w]; }
        }
        int64_t best_profit = NEG_INF; uint32_t best_mask = 0;
        for (size_t w = 0; w <= limit; ++w)
            if (dp[w] > best_profit || (dp[w] == best_profit && masks[w] < best_mask)) {
                best_profit = dp[w]; best_mask = masks[w];
            }
        if (best_profit > (int64_t)copies * fee[target]) {
            result[0] = 1; result[1] = (int64_t)copies; result[2] = best_mask;
            result[4] = old_cost + (int64_t)copies * fee[target] - best_profit; break;
        }
    }
    if (out == NULL || cap < 40) return -2;
    for (size_t i = 0; i < 5; ++i) put_i64(out, 8 * i, result[i]);
    return 40;
}
