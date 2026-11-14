#include <stddef.h>
#include <stdint.h>

/* Unverified deterministic planted 3-SAT generator draft. */
int64_t planted_3sat_clause_generator(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (!input || length < 5 || length > 83) return -1;
    int64_t n_raw = input[0], m_raw = input[1];
    if (n_raw < 3 || n_raw > 16 || m_raw < 0 || m_raw > 32) return -1;
    size_t n = (size_t)n_raw, m = (size_t)m_raw;
    if (length != 2+n+2*m) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2+i] != 0 && input[2+i] != 1) return -1;
    int64_t words[96];
    size_t choices = n*(n-1)*(n-2)/6;
    for (size_t clause = 0; clause < m; ++clause) {
        int64_t rank_raw = input[2+n+2*clause], mask = input[3+n+2*clause];
        if (rank_raw < 0 || (uint64_t)rank_raw >= choices || mask < 1 || mask > 7) return -1;
        size_t rank = (size_t)rank_raw, next = 0;
        for (size_t position = 0; position < 3; ++position) {
            for (size_t variable = next; variable < n-(2-position); ++variable) {
                size_t remaining = n-variable-1;
                size_t ways = position == 0 ? remaining*(remaining-1)/2 : position == 1 ? remaining : 1;
                if (rank >= ways) { rank -= ways; continue; }
                int64_t literal = (int64_t)(variable+1);
                int64_t satisfies = (mask >> position) & 1;
                words[3*clause+position] = input[2+variable] == satisfies ? literal : -literal;
                next = variable+1;
                break;
            }
        }
    }
    size_t bytes = 24*m;
    if (bytes != 0 && (!output || capacity < bytes)) return -2;
    for (size_t i = 0; i < 3*m; ++i) {
        uint64_t bits = (uint64_t)words[i];
        for (size_t b = 0; b < 8; ++b) output[8*i+b] = (uint8_t)(bits >> (8*b));
    }
    return (int64_t)bytes;
}
