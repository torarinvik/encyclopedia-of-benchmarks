#include <stddef.h>
#include <stdint.h>

enum { MAX_VARS = 12, MAX_CLAUSES = 32, MAX_INPUT = 98, MAX_OUTPUT = 96 };
static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[at + i] = (uint8_t)(bits & 255u); bits >>= 8; }
}

int64_t random_planted_3sat_majority_vote(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 3 || input[0] > MAX_VARS || input[1] < 0 || input[1] > MAX_CLAUSES) return -1;
    int n = (int)input[0], m = (int)input[1];
    if (length != (size_t)(2 + 3 * m)) return -1;
    int positive[MAX_VARS] = {0}, negative[MAX_VARS] = {0};
    for (int c = 0; c < m; ++c) {
        int seen[MAX_VARS] = {0};
        for (int j = 0; j < 3; ++j) {
            int64_t literal = input[2 + 3 * c + j];
            if (literal == 0 || literal < -n || literal > n) return -1;
            int variable = (int)(literal > 0 ? literal : -literal) - 1;
            if (seen[variable]) return -1;
            seen[variable] = 1;
            if (literal > 0) ++positive[variable]; else ++negative[variable];
        }
    }
    size_t bytes = 8u * (size_t)n;
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT] = {0};
    for (int v = 0; v < n; ++v) put_i64(staged, 8u * (size_t)v, positive[v] > negative[v] ? 1 : -1);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
