#include <stddef.h>
#include <stdint.h>

#define MAX_REQUESTS 7
#define MAX_FILES 8
#define MAX_INPUT 16

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t greedy_dual_weighted_caching(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t cache_capacity = input[0], count_value = input[1];
    if (cache_capacity < 1 || cache_capacity > MAX_FILES || count_value < 0 ||
        count_value > MAX_REQUESTS || length != 2 + 2 * (size_t)count_value) return -1;

    int64_t known_cost[MAX_FILES] = {0};
    int seen[MAX_FILES] = {0};
    for (size_t request = 0; request < (size_t)count_value; ++request) {
        const int64_t id = input[2 + 2 * request], cost = input[3 + 2 * request];
        if (id < 0 || id >= MAX_FILES || cost < 0 || cost > 20) return -1;
        if (seen[id] && known_cost[id] != cost) return -1;
        seen[id] = 1;
        known_cost[id] = cost;
    }

    int64_t ids[MAX_FILES] = {0}, credits[MAX_FILES] = {0};
    size_t resident_count = 0;
    int64_t misses = 0, total_cost = 0;
    uint64_t hit_signature = 0, eviction_signature = 0, resident_mask = 0;
    for (size_t request = 0; request < (size_t)count_value; ++request) {
        const int64_t id = input[2 + 2 * request], cost = input[3 + 2 * request];
        size_t position = 0;
        while (position < resident_count && ids[position] != id) ++position;
        if (position < resident_count) {
            hit_signature |= UINT64_C(1) << request;
            credits[position] = cost;
            continue;
        }
        ++misses;
        total_cost += cost;
        uint64_t evicted_mask = 0;
        while (resident_count >= (size_t)cache_capacity) {
            int64_t delta = credits[0];
            for (size_t i = 1; i < resident_count; ++i) if (credits[i] < delta) delta = credits[i];
            size_t kept = 0;
            for (size_t i = 0; i < resident_count; ++i) {
                credits[i] -= delta;
                if (credits[i] == 0) evicted_mask |= UINT64_C(1) << ids[i];
                else { ids[kept] = ids[i]; credits[kept] = credits[i]; ++kept; }
            }
            resident_count = kept;
        }
        eviction_signature |= evicted_mask << (8 * request);
        ids[resident_count] = id;
        credits[resident_count] = cost;
        ++resident_count;
    }
    for (size_t i = 0; i < resident_count; ++i) resident_mask |= UINT64_C(1) << ids[i];
    if (output == NULL || output_capacity < 40) return -2;
    uint8_t staged[40] = {0};
    store_i64_le(staged, 0, misses);
    store_i64_le(staged, 8, total_cost);
    store_i64_le(staged, 16, (int64_t)hit_signature);
    store_i64_le(staged, 24, (int64_t)eviction_signature);
    store_i64_le(staged, 32, (int64_t)resident_mask);
    for (size_t byte = 0; byte < 40; ++byte) output[byte] = staged[byte];
    return 40;
}
