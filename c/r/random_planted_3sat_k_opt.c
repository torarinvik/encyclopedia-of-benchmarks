#include <stddef.h>
#include <stdint.h>

enum { MAX_VARS = 12, MAX_CLAUSES = 32, MAX_INPUT = 98, MAX_OUTPUT = 104 };
static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[at + i] = (uint8_t)(bits & 255u); bits >>= 8; }
}
static uint32_t sat_set(const int *clauses, int m, int n, unsigned code) {
    uint32_t set = 0;
    for (int c = 0; c < m; ++c) {
        int satisfied = 0;
        for (int j = 0; j < 3; ++j) {
            int lit = clauses[3 * c + j], v = lit > 0 ? lit - 1 : -lit - 1;
            int truth = (int)((code >> (n - 1 - v)) & 1u);
            if (truth == (lit > 0)) satisfied = 1;
        }
        if (satisfied) set |= (uint32_t)1u << c;
    }
    return set;
}

int64_t random_planted_3sat_k_opt(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 3 || input[0] > MAX_VARS || input[1] < 0 || input[1] > MAX_CLAUSES) return -1;
    int n = (int)input[0], m = (int)input[1];
    if (length != (size_t)(2 + 3 * m)) return -1;
    int clauses[MAX_CLAUSES * 3] = {0}, positive[MAX_VARS] = {0}, negative[MAX_VARS] = {0};
    for (int c = 0; c < m; ++c) {
        int seen[MAX_VARS] = {0};
        for (int j = 0; j < 3; ++j) {
            int64_t raw = input[2 + 3 * c + j];
            if (raw == 0 || raw < -n || raw > n) return -1;
            int lit = (int)raw, v = lit > 0 ? lit - 1 : -lit - 1;
            if (seen[v]) return -1;
            seen[v] = 1; clauses[3 * c + j] = lit;
            if (lit > 0) ++positive[v]; else ++negative[v];
        }
    }
    unsigned current = 0;
    for (int v = 0; v < n; ++v) if (positive[v] > negative[v]) current |= 1u << (n - 1 - v);
    uint32_t all_clauses = m == 32 ? UINT32_MAX : (m == 0 ? 0u : (((uint32_t)1u << m) - 1u));
    int status = 0, k = 1;
    while (1) {
        uint32_t before = sat_set(clauses, m, n, current);
        if (before == all_clauses) { status = 1; break; }
        int found = 0;
        unsigned limit = 1u << n;
        for (unsigned candidate = 0; candidate < limit; ++candidate) {
            unsigned diff = current ^ candidate;
            int distance = 0;
            for (unsigned x = diff; x != 0; x &= x - 1u) ++distance;
            if (distance == 0 || distance > k) continue;
            uint32_t after = sat_set(clauses, m, n, candidate);
            if (after != before && (after & before) == before) { current = candidate; found = 1; break; }
        }
        if (found) continue;
        if (k == n) { status = 0; break; }
        ++k;
    }
    size_t bytes = 8u * (size_t)(n + 1);
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT] = {0};
    put_i64(staged, 0, status);
    for (int v = 0; v < n; ++v) {
        int truth = (int)((current >> (n - 1 - v)) & 1u);
        put_i64(staged, 8u * (size_t)(v + 1), truth ? 1 : -1);
    }
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
