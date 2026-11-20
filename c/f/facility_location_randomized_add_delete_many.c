#include <stddef.h>
#include <stdint.h>

#define MAX_N 5
#define MAX_F 5
#define MAX_Q 8
#define MAX_P 10
#define MAX_VALID 127
#define MAX_PARSEABLE 128
#define MAX_OUTPUT 192

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[at + i] = (uint8_t)(bits & 255U); bits >>= 8; }
}

static int64_t state_cost(size_t n, size_t f, const int64_t d[MAX_P][MAX_P],
                          const int64_t *fee, const int64_t *demand,
                          const int64_t *assignment, uint32_t mask) {
    int64_t total = 0;
    for (size_t s = 0; s < f; ++s) if (mask & (UINT32_C(1) << s)) total += fee[s];
    for (size_t j = 0; j < n; ++j)
        total += demand[j] * d[j][n + (size_t)assignment[j]];
    return total;
}

int64_t facility_location_randomized_add_delete_many(const int64_t *in, size_t len,
                                                      uint8_t *out, size_t cap) {
    if (in == NULL || len < 12 || len > MAX_PARSEABLE) return -1;
    int64_t nr = in[0], fr = in[1], qr = in[2], raw_mask = in[3];
    if (nr < 1 || nr > MAX_N || fr < 1 || fr > MAX_F || qr < 1 || qr > MAX_Q
        || raw_mask <= 0 || (uint64_t)raw_mask >= (UINT64_C(1) << fr)) return -1;
    size_t n = (size_t)nr, f = (size_t)fr, q = (size_t)qr, pcount = n + f;
    if (len != 4 + 2 * n + pcount * pcount + f + q) return -1;
    uint32_t mask = (uint32_t)raw_mask;
    int64_t assignment[MAX_N] = {0}, demand[MAX_N] = {0};
    int64_t d[MAX_P][MAX_P] = {{0}}, fee[MAX_F] = {0}, tape[MAX_Q] = {0};
    size_t pos = 4;
    for (size_t j = 0; j < n; ++j) {
        assignment[j] = in[pos++];
        if (assignment[j] < 0 || assignment[j] >= fr
            || !(mask & (UINT32_C(1) << (size_t)assignment[j]))) return -1;
    }
    for (size_t j = 0; j < n; ++j) { demand[j] = in[pos++]; if (demand[j] < 1 || demand[j] > 10) return -1; }
    for (size_t i = 0; i < pcount; ++i) for (size_t j = 0; j < pcount; ++j) {
        int64_t value = in[pos++]; if (value < 0 || value > 1000) return -1; d[i][j] = value;
    }
    for (size_t i = 0; i < pcount; ++i) {
        if (d[i][i] != 0) return -1;
        for (size_t j = 0; j < pcount; ++j) {
            if (i != j && d[i][j] == 0) return -1;
            if (d[i][j] != d[j][i]) return -1;
            for (size_t k = 0; k < pcount; ++k)
                if (d[i][j] > d[i][k] + d[k][j]) return -1;
        }
    }
    for (size_t s = 0; s < f; ++s) { fee[s] = in[pos++]; if (fee[s] < 0 || fee[s] > 1000) return -1; }
    for (size_t t = 0; t < q; ++t) { tape[t] = in[pos++]; if (tape[t] < 0 || tape[t] >= fr) return -1; }

    int64_t trace_cost[MAX_Q] = {0};
    int64_t trace_accept[MAX_Q] = {0};
    int64_t current_cost = state_cost(n, f, d, fee, demand, assignment, mask);
    int64_t accepted_count = 0;
    for (size_t step = 0; step < q; ++step) {
        size_t candidate = (size_t)tape[step];
        uint32_t bit = UINT32_C(1) << candidate;
        int64_t did_accept = 0;
        if (!(mask & bit)) {
            int closer[MAX_N] = {0};
            int64_t gain = -fee[candidate];
            for (size_t j = 0; j < n; ++j) {
                size_t old = (size_t)assignment[j];
                if (d[j][n + candidate] < d[j][n + old]) {
                    closer[j] = 1;
                    gain += demand[j] * (d[j][n + old] - d[j][n + candidate]);
                }
            }
            uint32_t drop_mask = 0;
            for (size_t s = 0; s < f; ++s) if (mask & (UINT32_C(1) << s)) {
                int64_t center_gain = fee[s];
                for (size_t j = 0; j < n; ++j)
                    if ((size_t)assignment[j] == s && !closer[j])
                        center_gain += demand[j] * (d[j][n + s] - d[j][n + candidate]);
                if (center_gain > 0) { drop_mask |= UINT32_C(1) << s; gain += center_gain; }
            }
            if (gain > 0) {
                mask = (mask | bit) & ~drop_mask;
                for (size_t j = 0; j < n; ++j)
                    if (closer[j] || (drop_mask & (UINT32_C(1) << (size_t)assignment[j])))
                        assignment[j] = (int64_t)candidate;
                current_cost = state_cost(n, f, d, fee, demand, assignment, mask);
                did_accept = 1;
                ++accepted_count;
            }
        }
        trace_cost[step] = current_cost;
        trace_accept[step] = did_accept;
    }
    size_t words = 2 * q + 3 + n, needed = words * 8;
    if (out == NULL || cap < needed) return -2;
    size_t at = 0;
    for (size_t step = 0; step < q; ++step) { put_i64(out, at, trace_cost[step]); at += 8; }
    for (size_t step = 0; step < q; ++step) { put_i64(out, at, trace_accept[step]); at += 8; }
    put_i64(out, at, current_cost); at += 8;
    put_i64(out, at, (int64_t)mask); at += 8;
    for (size_t j = 0; j < n; ++j) { put_i64(out, at, assignment[j]); at += 8; }
    put_i64(out, at, accepted_count); at += 8;
    return (int64_t)at;
}
