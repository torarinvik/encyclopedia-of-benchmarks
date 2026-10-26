/* Clean-room bounded GBBS approximate set-cover profile; see package MIT notice. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_SETS = 8, MAX_ELEMENTS = 8, MAX_INPUT = 10 };

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[offset + i] = (uint8_t)bits; bits >>= 8; }
}

int64_t gbbs_approximate_set_cover(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t ns64 = input[0];
    if (ns64 < 1 || ns64 > MAX_SETS) return -1;
    size_t ns = (size_t)ns64, ne = ns;
    if (length != 1 + ns) return -1;
    uint16_t valid = (uint16_t)((1u << ne) - 1u);
    uint16_t sets[MAX_SETS] = {0};
    for (size_t s = 0; s < ns; ++s) {
        if (input[1 + s] < 0 || ((uint64_t)input[1 + s] & ~(uint64_t)valid) != 0) return -1;
        sets[s] = (uint16_t)input[1 + s];
        if (sets[s] & (1u << s)) return -1;
    }
    for (size_t u = 0; u < ns; ++u)
        for (size_t v = 0; v < ns; ++v)
            if (((sets[u] >> v) & 1u) != ((sets[v] >> u) & 1u)) return -1;
    if (output == NULL || capacity < 16) return -2;
    uint16_t uncovered = valid;
    uint16_t selected = 0;
    size_t bucket[MAX_SETS] = {0};
    for (size_t s = 0; s < ns; ++s) {
        uint16_t bits = sets[s];
        while (bits != 0) { bits = (uint16_t)(bits & (uint16_t)(bits - 1)); ++bucket[s]; }
    }
    size_t round = 0;
    while (uncovered != 0) {
        size_t degree[MAX_SETS] = {0};
        size_t top = 0;
        for (size_t s = 0; s < ns; ++s) if (bucket[s] > top) top = bucket[s];
        if (top == 0) break;
        uint8_t eligible[MAX_SETS] = {0};
        size_t eligible_count = 0;
        for (size_t s = 0; s < ns; ++s) if (bucket[s] == top) {
            uint16_t bits = (uint16_t)(sets[s] & uncovered);
            while (bits != 0) { bits = (uint16_t)(bits & (uint16_t)(bits - 1)); ++degree[s]; }
            bucket[s] = degree[s];
            if (degree[s] >= top) { eligible[s] = 1; ++eligible_count; }
        }
        size_t priority[MAX_SETS];
        size_t rank_next = 0;
        for (size_t r = 0; r < ns; ++r) {
            size_t s = (round + r) % ns;
            if (eligible[s]) priority[rank_next++] = s;
        }
        size_t wins[MAX_SETS] = {0};
        for (size_t e = 0; e < ne; ++e) {
            uint16_t bit = (uint16_t)(1u << e);
            if ((uncovered & bit) == 0) continue;
            size_t winner = ns;
            for (size_t r = 0; r < rank_next; ++r) {
                size_t s = priority[r];
                if ((sets[s] & bit) != 0) { winner = s; break; }
            }
            if (winner != ns) ++wins[winner];
        }
        uint16_t round_cover = 0;
        for (size_t s = 0; s < ns; ++s) if (eligible[s] && wins[s] >= top) round_cover |= (uint16_t)(1u << s);
        if (round_cover == 0 && eligible_count != 0) return -1;
        selected |= round_cover;
        uint16_t covered = 0;
        for (size_t s = 0; s < ns; ++s) if (round_cover & (1u << s)) covered |= sets[s];
        uncovered = (uint16_t)(uncovered & (uint16_t)~covered);
        for (size_t s = 0; s < ns; ++s) if (round_cover & (1u << s)) bucket[s] = 0;
        ++round;
    }
    store_i64_le(output, 0, (int64_t)selected);
    store_i64_le(output, 8, (int64_t)uncovered);
    return 16;
}
