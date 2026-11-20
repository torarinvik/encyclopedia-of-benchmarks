#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 24, MAX_PARSEABLE_IN = 99, MAX_WORDS = 44, MAX_OUTPUT_BYTES = 352 };

typedef struct {
    int len[MAX_M];
    int lit[MAX_M][3];
    int active[MAX_M];
} Formula;

typedef struct {
    int literal;
    int kind;
    int bi;
    int bj;
} Event;

static void store_i64(uint8_t *dst, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) {
        dst[at + i] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

static int valid_clause(const int64_t *input, size_t base, int n, int *len, int out[3]) {
    int64_t raw_k = input[base];
    if (raw_k < 1 || raw_k > 3) return 0;
    int k = (int)raw_k;
    int seen[MAX_N] = {0};
    for (int i = 0; i < 3; ++i) {
        int64_t raw = input[base + 1u + (size_t)i];
        if (i < k) {
            if (raw == 0 || raw < -n || raw > n) return 0;
            int v = (int)(raw > 0 ? raw : -raw) - 1;
            if (seen[v]) return 0;
            seen[v] = 1;
            out[i] = (int)raw;
        } else if (raw != 0) {
            return 0;
        }
    }
    *len = k;
    return 1;
}

static int reduce_formula(Formula *f, int m, int assigned[MAX_N], int literal) {
    int v = (literal > 0 ? literal : -literal) - 1;
    int value = literal > 0 ? 1 : -1;
    if (assigned[v] != 0 && assigned[v] != value) return 0;
    assigned[v] = value;
    for (int c = 0; c < m; ++c) {
        if (!f->active[c]) continue;
        int satisfied = 0;
        for (int j = 0; j < f->len[c]; ++j) if (f->lit[c][j] == literal) satisfied = 1;
        if (satisfied) {
            f->active[c] = 0;
            continue;
        }
        int write = 0;
        for (int j = 0; j < f->len[c]; ++j) {
            if (f->lit[c][j] != -literal) f->lit[c][write++] = f->lit[c][j];
        }
        f->len[c] = write;
        if (write == 0) return 0;
    }
    return 1;
}

static int force_units(Formula *f, int m, int assigned[MAX_N], Event *events,
                       int *event_count, int record) {
    for (;;) {
        int unit = 0;
        for (int c = 0; c < m; ++c) {
            if (f->active[c] && f->len[c] == 1) { unit = f->lit[c][0]; break; }
        }
        if (unit == 0) return 1;
        if (record) events[(*event_count)++] = (Event){unit, 1, -1, -1};
        if (!reduce_formula(f, m, assigned, unit)) return 0;
    }
}

static void all_degrees(const Formula *f, int m, int n, int pos[MAX_N], int neg[MAX_N]) {
    for (int v = 0; v < n; ++v) pos[v] = neg[v] = 0;
    for (int c = 0; c < m; ++c) if (f->active[c]) {
        for (int j = 0; j < f->len[c]; ++j) {
            int x = f->lit[c][j];
            if (x > 0) ++pos[x - 1]; else ++neg[-x - 1];
        }
    }
}

static int bucket_literal(const Formula *f, int m, int n, const int assigned[MAX_N],
                          int bi, int bj) {
    int pos[MAX_N], neg[MAX_N];
    all_degrees(f, m, n, pos, neg);
    for (int v = 0; v < n; ++v) {
        if (assigned[v]) continue;
        int p = pos[v] < 10 ? pos[v] : 10;
        int q = neg[v] < 10 ? neg[v] : 10;
        if (p == bi && q == bj) return v + 1;
        if (q == bi && p == bj) return -(v + 1);
    }
    return 0;
}

static void flow_sums(const Formula *f, int m, int n, int *s2, int *s3, int *den) {
    int p2[MAX_N] = {0}, n2[MAX_N] = {0};
    int p3[MAX_N] = {0}, n3[MAX_N] = {0};
    int c2 = 0;
    for (int c = 0; c < m; ++c) if (f->active[c]) {
        if (f->len[c] == 2) ++c2;
        int *p = f->len[c] == 2 ? p2 : (f->len[c] == 3 ? p3 : NULL);
        int *q = f->len[c] == 2 ? n2 : (f->len[c] == 3 ? n3 : NULL);
        if (p == NULL) continue;
        for (int j = 0; j < f->len[c]; ++j) {
            int x = f->lit[c][j];
            if (x > 0) ++p[x - 1]; else ++q[-x - 1];
        }
    }
    *s2 = *s3 = 0;
    for (int c = 0; c < m; ++c) if (f->active[c] && f->len[c] == 2) {
        for (int j = 0; j < 2; ++j) {
            int x = -f->lit[c][j];
            *s2 += x > 0 ? p2[x - 1] : n2[-x - 1];
            *s3 += x > 0 ? p3[x - 1] : n3[-x - 1];
        }
    }
    *den = c2 == 0 ? 1 : 2 * c2;
}

static int choose_bucket(const Formula *f, int m, int n, const int assigned[MAX_N],
                         int *best_i, int *best_j) {
    int old2, old3, oldden;
    flow_sums(f, m, n, &old2, &old3, &oldden);
    int have = 0;
    int64_t best_num = 0, best_den = 1;
    for (int bi = 0; bi <= 10; ++bi) for (int bj = 0; bj <= 10; ++bj) {
        int literal = bucket_literal(f, m, n, assigned, bi, bj);
        if (literal == 0) continue;
        Formula trial = *f;
        int trial_assigned[MAX_N];
        for (int v = 0; v < n; ++v) trial_assigned[v] = assigned[v];
        if (!reduce_formula(&trial, m, trial_assigned, literal) ||
            !force_units(&trial, m, trial_assigned, NULL, NULL, 0)) continue;
        int next2, next3, nextden;
        flow_sums(&trial, m, n, &next2, &next3, &nextden);
        int64_t numerator = (int64_t)next2 * oldden - (int64_t)old2 * nextden;
        int64_t denominator = (int64_t)next3 * oldden - (int64_t)old3 * nextden;
        if (denominator == 0) continue;
        if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
        if (!have || numerator * best_den > best_num * denominator ||
            (numerator * best_den == best_num * denominator &&
             (bi < *best_i || (bi == *best_i && bj < *best_j)))) {
            have = 1; best_num = numerator; best_den = denominator;
            *best_i = bi; *best_j = bj;
        }
    }
    return have;
}

int64_t random_3sat_cl_bucket_heuristic(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > MAX_PARSEABLE_IN) return -1;
    int64_t raw_n = input[0], raw_m = input[1];
    if (raw_n < 1 || raw_n > MAX_N || raw_m < 0 || raw_m > MAX_M ||
        length != 2u + 4u * (size_t)raw_m) return -1;
    int n = (int)raw_n, m = (int)raw_m;
    Formula formula = {0};
    for (int c = 0; c < m; ++c) {
        if (!valid_clause(input, 2u + 4u * (size_t)c, n, &formula.len[c], formula.lit[c])) return -1;
        formula.active[c] = 1;
    }

    int assigned[MAX_N] = {0};
    Event events[MAX_N];
    int event_count = 0;
    int status = 0;
    if (!force_units(&formula, m, assigned, events, &event_count, 1)) status = 1;
    while (status == 0) {
        int remaining = 0;
        for (int v = 0; v < n; ++v) remaining += assigned[v] == 0;
        if (remaining == 0) break;
        int bi = -1, bj = -1;
        if (!choose_bucket(&formula, m, n, assigned, &bi, &bj)) { status = 2; break; }
        int literal = bucket_literal(&formula, m, n, assigned, bi, bj);
        if (literal == 0) { status = 2; break; }
        events[event_count++] = (Event){literal, 0, bi, bj};
        if (!reduce_formula(&formula, m, assigned, literal)) { status = 1; break; }
        if (!force_units(&formula, m, assigned, events, &event_count, 1)) { status = 1; break; }
    }

    int64_t words[MAX_WORDS] = {0};
    int at = 0;
    words[at++] = status;
    words[at++] = n;
    int assigned_count = 0;
    for (int v = 0; v < n; ++v) assigned_count += assigned[v] != 0;
    words[at++] = assigned_count;
    for (int v = 0; v < n; ++v) words[at++] = assigned[v];
    words[at++] = event_count;
    for (int i = 0; i < event_count; ++i) {
        words[at++] = events[i].literal;
        words[at++] = events[i].kind;
        words[at++] = events[i].bi;
        words[at++] = events[i].bj;
    }
    size_t bytes = (size_t)at * 8u;
    if (!output || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (int i = 0; i < at; ++i) store_i64(staged, 8u * (size_t)i, words[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
