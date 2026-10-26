#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_WEIGHT = 32, MAX_INPUT = 25, MAX_OUTPUT = 104 };

static void put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[offset + i] = (uint8_t)bits; bits >>= 8; }
}

int64_t universal_sequencing_doubling(const int64_t *values, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (!values || length < 3 || length > MAX_INPUT || values[0] < 1 || values[0] > MAX_N ||
        length != 1 + 2 * (size_t)values[0]) return -1;
    const int n = (int)values[0];
    int64_t processing[MAX_N] = {0};
    int weight[MAX_N] = {0};
    int total_weight = 0;
    for (int job = 0; job < n; ++job) {
        const int64_t p = values[1 + 2 * job], w = values[2 + 2 * job];
        if (p < 1 || p > 255 || w < 1 || w > MAX_WEIGHT) return -1;
        processing[job] = p;
        weight[job] = (int)w;
        total_weight += (int)w;
    }
    if (total_weight > MAX_WEIGHT || (total_weight & (total_weight - 1)) != 0) return -1;

    uint16_t level_sets[6] = {0};
    int levels = 0;
    for (int bound = 1; bound <= total_weight; bound *= 2, ++levels) {
        int64_t best[MAX_WEIGHT + 1] = {0};
        uint16_t masks[MAX_WEIGHT + 1] = {0};
        uint8_t reachable[MAX_WEIGHT + 1] = {0};
        reachable[0] = 1;
        for (int job = 0; job < n; ++job) {
            for (int used = bound; used >= weight[job]; --used) {
                if (!reachable[used - weight[job]]) continue;
                const int64_t candidate = best[used - weight[job]] + processing[job];
                const uint16_t candidate_mask = (uint16_t)(masks[used - weight[job]] | (1u << job));
                if (!reachable[used] || candidate > best[used] ||
                    (candidate == best[used] && candidate_mask < masks[used])) {
                    reachable[used] = 1;
                    best[used] = candidate;
                    masks[used] = candidate_mask;
                }
            }
        }
        int64_t maximum = -1;
        uint16_t selected = 0;
        for (int used = 0; used <= bound; ++used) {
            if (reachable[used] && (best[used] > maximum ||
                (best[used] == maximum && masks[used] < selected))) {
                maximum = best[used];
                selected = masks[used];
            }
        }
        level_sets[levels] = selected;
    }

    int rank[MAX_N];
    for (int job = 0; job < n; ++job) {
        rank[job] = -1;
        for (int level = 0; level < levels; ++level)
            if ((level_sets[level] & (1u << job)) != 0) { rank[job] = level; break; }
        if (rank[job] < 0) return -1;
    }
    int64_t staged[MAX_N + 1] = {0};
    staged[0] = n;
    int out_count = 1;
    for (int level = levels - 1; level >= 0; --level)
        for (int job = 0; job < n; ++job)
            if (rank[job] == level) staged[out_count++] = job;
    const size_t bytes = 8 * (size_t)out_count;
    uint8_t bytes_out[MAX_OUTPUT] = {0};
    for (int i = 0; i < out_count; ++i) put_i64(bytes_out, 8 * (size_t)i, staged[i]);
    if (!output || capacity < bytes) return -2;
    for (size_t i = 0; i < bytes; ++i) output[i] = bytes_out[i];
    return (int64_t)bytes;
}
