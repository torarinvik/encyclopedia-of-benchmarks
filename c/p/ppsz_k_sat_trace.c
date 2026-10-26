#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_CLAUSES = 12, MAX_INPUT = 54, MAX_OUTPUT = 72 };
static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[at + i] = (uint8_t)(bits & 255); bits >>= 8; }
}
static int fixed_mask(int mask, const int assignment[MAX_N], int n) {
    for (int i = 0; i < n; ++i) if (assignment[i] >= 0) {
        if (assignment[i]) mask |= 1 << i; else mask &= ~(1 << i);
    }
    return mask;
}
static int clause_true(const int clause[3], int mask) {
    for (int j = 0; j < 3; ++j) {
        int literal = clause[j], bit = (mask >> ((literal > 0 ? literal : -literal) - 1)) & 1;
        if ((literal > 0 && bit) || (literal < 0 && !bit)) return 1;
    }
    return 0;
}
static int selected_true(const int clauses[MAX_CLAUSES][3], int m, int subset, int mask) {
    for (int i = 0; i < m; ++i) if ((subset & (1 << i)) && !clause_true(clauses[i], mask)) return 0;
    return 1;
}
static int popcount(int value) { int count = 0; while (value) { count += value & 1; value >>= 1; } return count; }
static int current_satisfiable(int n, int m, const int clauses[MAX_CLAUSES][3], const int assignment[MAX_N]) {
    for (int mask = 0; mask < (1 << n); ++mask)
        if (selected_true(clauses, m, (1 << m) - 1, fixed_mask(mask, assignment, n))) return 1;
    return 0;
}
static int find_force(int n, int m, const int clauses[MAX_CLAUSES][3], const int assignment[MAX_N], int *forced_var, int *forced_value) {
    if (!current_satisfiable(n, m, clauses, assignment)) return 0;
    int threshold = 0; while ((1 << (threshold + 1)) <= n) ++threshold;
    int implied[MAX_N]; for (int i = 0; i < MAX_N; ++i) implied[i] = -1;
    for (int subset = 1; subset < (1 << m); ++subset) {
        if (popcount(subset) > threshold) continue;
        int seen_zero[MAX_N] = {0}, seen_one[MAX_N] = {0};
        for (int mask = 0; mask < (1 << n); ++mask) {
            int full = fixed_mask(mask, assignment, n);
            if (selected_true(clauses, m, subset, full)) for (int var = 0; var < n; ++var)
                if (assignment[var] < 0) { if ((full >> var) & 1) seen_one[var] = 1; else seen_zero[var] = 1; }
        }
        for (int var = 0; var < n; ++var) if (assignment[var] < 0 && seen_zero[var] != seen_one[var] && implied[var] < 0)
            implied[var] = seen_one[var] ? 1 : 0;
    }
    for (int var = 0; var < n; ++var) if (implied[var] >= 0) { *forced_var = var; *forced_value = implied[var]; return 1; }
    return 0;
}

int64_t ppsz_k_sat_trace(const int64_t *v, size_t length, uint8_t *output, size_t capacity) {
    if (!v || length < 2 || length > MAX_INPUT || v[0] < 3 || v[0] > MAX_N || v[1] < 0 || v[1] > MAX_CLAUSES) return -1;
    int n = (int)v[0], m = (int)v[1]; if (length != (size_t)(2 + 3 * m + 2 * n)) return -1;
    int clauses[MAX_CLAUSES][3] = {{0}};
    for (int i = 0; i < m; ++i) {
        int seen[MAX_N] = {0};
        for (int j = 0; j < 3; ++j) {
            int64_t literal = v[2 + 3 * i + j]; if (literal == 0 || literal < -n || literal > n) return -1;
            int variable = (int)(literal > 0 ? literal : -literal) - 1; if (seen[variable]) return -1; seen[variable] = 1; clauses[i][j] = (int)literal;
        }
    }
    int permutation[MAX_N], beta[MAX_N], assigned[MAX_N] = {-1,-1,-1,-1,-1,-1,-1,-1}, seen_var[MAX_N] = {0};
    int start = 2 + 3 * m;
    for (int i = 0; i < n; ++i) { int64_t x = v[start + i]; if (x < 0 || x >= n || seen_var[x]) return -1; permutation[i] = (int)x; seen_var[x] = 1; }
    for (int i = 0; i < n; ++i) { int64_t bit = v[start + n + i]; if (bit != 0 && bit != 1) return -1; beta[i] = (int)bit; }
    for (int step = 0; step < n; ++step) {
        int force_var, force_value;
        while (find_force(n, m, clauses, assigned, &force_var, &force_value)) assigned[force_var] = force_value;
        int x = permutation[step]; if (assigned[x] < 0) assigned[x] = beta[x];
    }
    int full = 0; for (int i = 0; i < n; ++i) if (assigned[i]) full |= 1 << i;
    int sat = selected_true(clauses, m, (1 << m) - 1, full);
    const size_t bytes = 8 * (size_t)(n + 1); if (!output || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT]; put_i64(staged, 0, sat);
    for (int i = 0; i < n; ++i) put_i64(staged, 8 * (size_t)(i + 1), assigned[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i]; return (int64_t)bytes;
}
