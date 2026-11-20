#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define CFL_N 4
#define CFL_F 3
#define CFL_Q0 4
#define CFL_COPIES 644
#define CFL_CANDIDATE_COPIES 648
#define CFL_POINTS 7
#define CFL_VALID 62
#define CFL_PARSEABLE 63
#define CFL_OUTPUT 5208
#define CFL_NEG (INT64_MIN / 4)

static void cfl_put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8 * b));
}

static int64_t cfl_assign(size_t n, size_t f, const int64_t d[CFL_POINTS][CFL_POINTS],
                          const int64_t fee[CFL_F], const int64_t cap[CFL_F],
                          const int64_t *types, size_t copies,
                          int64_t assignment[CFL_N]) {
    size_t multiplicity[CFL_F] = {0};
    for (size_t i = 0; i < copies; ++i) ++multiplicity[(size_t)types[i]];
    size_t combinations = 1;
    for (size_t j = 0; j < n; ++j) combinations *= f;
    int64_t best = INT64_MAX;
    int64_t best_types[CFL_N] = {0};
    for (size_t code = 0; code < combinations; ++code) {
        size_t rem = code;
        int64_t candidate[CFL_N] = {0};
        size_t loads[CFL_F] = {0};
        int64_t service = 0;
        for (size_t j = n; j-- > 0;) {
            size_t kind = rem % f;
            rem /= f;
            candidate[j] = (int64_t)kind;
            ++loads[kind];
            service += d[j][n + kind];
        }
        bool feasible = true;
        for (size_t kind = 0; kind < f; ++kind)
            if (loads[kind] > multiplicity[kind] * (size_t)cap[kind]) feasible = false;
        if (feasible && service < best) {
            best = service;
            for (size_t j = 0; j < n; ++j) best_types[j] = candidate[j];
        }
    }
    size_t copy_load[CFL_CANDIDATE_COPIES] = {0};
    for (size_t j = 0; j < n; ++j) {
        assignment[j] = -1;
        for (size_t i = 0; i < copies; ++i) {
            size_t kind = (size_t)types[i];
            if (kind == (size_t)best_types[j] && copy_load[i] < (size_t)cap[kind]) {
                assignment[j] = (int64_t)i;
                ++copy_load[i];
                break;
            }
        }
    }
    for (size_t i = 0; i < copies; ++i) best += fee[(size_t)types[i]];
    return best;
}

static void cfl_insert_type(int64_t *types, size_t *count, int64_t kind) {
    size_t at = *count;
    while (at > 0 && types[at - 1] > kind) {
        types[at] = types[at - 1];
        --at;
    }
    types[at] = kind;
    ++*count;
}

static int64_t cfl_t_hunt(size_t n, size_t f,
                          const int64_t d[CFL_POINTS][CFL_POINTS],
                          const int64_t fee[CFL_F], const int64_t cap[CFL_F],
                          const int64_t *types, size_t copies,
                          const int64_t *assignment, size_t target, size_t l,
                          size_t *loads, int64_t *profits, bool take[CFL_COPIES][CFL_N + 1],
                          bool selected[CFL_COPIES]) {
    for (size_t i = 0; i < copies; ++i) { loads[i] = 0; profits[i] = fee[(size_t)types[i]]; }
    for (size_t j = 0; j < n; ++j) {
        size_t copy = (size_t)assignment[j];
        ++loads[copy];
        size_t old_type = (size_t)types[copy];
        profits[copy] += d[j][n + old_type] - d[j][n + target];
    }
    size_t limit = l * (size_t)cap[target];
    if (limit > n) limit = n;
    int64_t dp[CFL_N + 1], next[CFL_N + 1];
    for (size_t w = 0; w <= limit; ++w) dp[w] = CFL_NEG;
    dp[0] = 0;
    for (size_t i = 0; i < copies; ++i) {
        for (size_t w = 0; w <= limit; ++w) { next[w] = dp[w]; take[i][w] = false; }
        for (size_t w = 0; w <= limit; ++w) {
            if (dp[w] == CFL_NEG || w + loads[i] > limit) continue;
            size_t nw = w + loads[i];
            int64_t value = dp[w] + profits[i];
            if (value > next[nw]) { next[nw] = value; take[i][nw] = true; }
        }
        for (size_t w = 0; w <= limit; ++w) dp[w] = next[w];
    }
    int64_t best = CFL_NEG;
    size_t best_weight = 0;
    for (size_t w = 0; w <= limit; ++w)
        if (dp[w] > best) { best = dp[w]; best_weight = w; }
    for (size_t i = 0; i < copies; ++i) selected[i] = false;
    for (size_t i = copies; i-- > 0;) {
        if (take[i][best_weight]) { selected[i] = true; best_weight -= loads[i]; }
    }
    (void)f;
    return best;
}

int64_t capacitated_facility_location_t_hunt_local_search(
    const int64_t *in, size_t len, uint8_t *out, size_t capacity) {
    if (in == NULL || len < 10 || len > CFL_PARSEABLE) return -1;
    int64_t n0 = in[0], f0 = in[1], q0 = in[2];
    if (n0 < 1 || n0 > CFL_N || f0 < 1 || f0 > CFL_F || q0 < 1 || q0 > CFL_Q0) return -1;
    size_t n = (size_t)n0, f = (size_t)f0, q = (size_t)q0, p = n + f;
    if (len != 3 + p * p + 2 * f + q) return -1;
    int64_t d[CFL_POINTS][CFL_POINTS] = {{0}}, fee[CFL_F] = {0}, cap[CFL_F] = {0};
    int64_t types[CFL_CANDIDATE_COPIES] = {0};
    size_t at = 3;
    for (size_t i = 0; i < p; ++i) for (size_t j = 0; j < p; ++j) {
        int64_t x = in[at++]; if (x < 0 || x > 20) return -1; d[i][j] = x;
    }
    for (size_t i = 0; i < p; ++i) {
        if (d[i][i] != 0) return -1;
        for (size_t j = 0; j < p; ++j) {
            if (i != j && d[i][j] == 0) return -1;
            if (d[i][j] != d[j][i]) return -1;
            for (size_t k = 0; k < p; ++k) if (d[i][j] > d[i][k] + d[k][j]) return -1;
        }
    }
    for (size_t i = 0; i < f; ++i) { fee[i] = in[at++]; if (fee[i] < 0 || fee[i] > 20) return -1; }
    for (size_t i = 0; i < f; ++i) { cap[i] = in[at++]; if (cap[i] < 1 || cap[i] > n0) return -1; }
    size_t copies = q;
    size_t total_capacity = 0;
    for (size_t i = 0; i < q; ++i) {
        types[i] = in[at++]; if (types[i] < 0 || types[i] >= f0) return -1;
        total_capacity += (size_t)cap[(size_t)types[i]];
    }
    if (total_capacity < n) return -1;
    for (size_t i = 1; i < copies; ++i) {
        int64_t value = types[i]; size_t j = i;
        while (j > 0 && types[j - 1] > value) { types[j] = types[j - 1]; --j; }
        types[j] = value;
    }
    int64_t assignment[CFL_N] = {0};
    int64_t current = cfl_assign(n, f, d, fee, cap, types, copies, assignment);
    size_t steps = 0;
    while (steps < 160) {
        bool moved = false;
        for (size_t target = 0; target < f; ++target) {
            int64_t candidate_types[CFL_CANDIDATE_COPIES];
            for (size_t i = 0; i < copies; ++i) candidate_types[i] = types[i];
            size_t candidate_count = copies;
            cfl_insert_type(candidate_types, &candidate_count, (int64_t)target);
            int64_t candidate_assignment[CFL_N] = {0};
            int64_t candidate_cost = cfl_assign(n, f, d, fee, cap, candidate_types,
                                                candidate_count, candidate_assignment);
            if (candidate_cost < current) {
                for (size_t i = 0; i < candidate_count; ++i) types[i] = candidate_types[i];
                copies = candidate_count; current = candidate_cost;
                for (size_t j = 0; j < n; ++j) assignment[j] = candidate_assignment[j];
                ++steps; moved = true; break;
            }
            size_t loads[CFL_COPIES]; int64_t profits[CFL_COPIES];
            bool take[CFL_COPIES][CFL_N + 1]; bool selected[CFL_COPIES];
            for (size_t l = 1; l <= n; ++l) {
                int64_t profit = cfl_t_hunt(n, f, d, fee, cap, types, copies,
                                            assignment, target, l, loads, profits,
                                            take, selected);
                if (profit <= (int64_t)l * fee[target]) continue;
                size_t drop_count = 0;
                for (size_t i = 0; i < copies; ++i) if (!selected[i]) candidate_types[drop_count++] = types[i];
                candidate_count = drop_count;
                for (size_t k = 0; k < l; ++k) cfl_insert_type(candidate_types, &candidate_count, (int64_t)target);
                candidate_cost = cfl_assign(n, f, d, fee, cap, candidate_types,
                                            candidate_count, candidate_assignment);
                if (candidate_cost < current) {
                    for (size_t i = 0; i < candidate_count; ++i) types[i] = candidate_types[i];
                    copies = candidate_count; current = candidate_cost;
                    for (size_t j = 0; j < n; ++j) assignment[j] = candidate_assignment[j];
                    ++steps; moved = true; break;
                }
            }
            if (moved) break;
        }
        if (!moved) break;
    }
    size_t words = 3 + copies + n, bytes = 8 * words;
    if (out == NULL || capacity < bytes) return -2;
    at = 0;
    cfl_put_i64(out, at, current); at += 8;
    cfl_put_i64(out, at, (int64_t)steps); at += 8;
    cfl_put_i64(out, at, (int64_t)copies); at += 8;
    for (size_t i = 0; i < copies; ++i) { cfl_put_i64(out, at, types[i]); at += 8; }
    for (size_t j = 0; j < n; ++j) { cfl_put_i64(out, at, assignment[j]); at += 8; }
    return (int64_t)bytes;
}
