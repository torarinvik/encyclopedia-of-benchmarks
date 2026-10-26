#include <stddef.h>
#include <stdint.h>

#define MAX_REQUESTS 7
#define MAX_FILES 8
#define MAX_INPUT 23

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t landlord_file_caching(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t capacity_value = input[0], count_value = input[1];
    if (capacity_value < 1 || capacity_value > 8 || count_value < 0 || count_value > MAX_REQUESTS ||
        length != 2 + 3 * (size_t)count_value) return -1;
    int64_t known_size[MAX_FILES] = {0}, known_cost[MAX_FILES] = {0};
    int seen[MAX_FILES] = {0};
    for (size_t request = 0; request < (size_t)count_value; ++request) {
        int64_t id = input[2 + 3 * request], size = input[3 + 3 * request], cost = input[4 + 3 * request];
        if (id < 0 || id >= MAX_FILES || size < 1 || size > 4 || size > capacity_value || cost < 0 || cost > 20) return -1;
        if (seen[id] && (known_size[id] != size || known_cost[id] != cost)) return -1;
        seen[id] = 1; known_size[id] = size; known_cost[id] = cost;
    }

    int64_t ids[MAX_FILES] = {0}, sizes[MAX_FILES] = {0}, credits[MAX_FILES] = {0};
    size_t resident_count = 0;
    int64_t misses = 0, total_cost = 0;
    uint64_t hit_signature = 0, eviction_signature = 0, resident_mask = 0;
    for (size_t request = 0; request < (size_t)count_value; ++request) {
        int64_t id = input[2 + 3 * request], size = input[3 + 3 * request], cost = input[4 + 3 * request];
        size_t position = 0;
        while (position < resident_count && ids[position] != id) ++position;
        if (position < resident_count) {
            hit_signature |= UINT64_C(1) << request;
            continue;
        }
        ++misses; total_cost += cost;
        uint64_t evicted_mask = 0;
        int64_t used = 0;
        for (size_t i = 0; i < resident_count; ++i) used += sizes[i];
        while (used + size > capacity_value) {
            int64_t delta = credits[0] / sizes[0];
            for (size_t i = 1; i < resident_count; ++i) {
                int64_t ratio = credits[i] / sizes[i];
                if (ratio < delta) delta = ratio;
            }
            size_t kept = 0;
            used = 0;
            for (size_t i = 0; i < resident_count; ++i) {
                credits[i] -= delta * sizes[i];
                if (credits[i] == 0) evicted_mask |= UINT64_C(1) << ids[i];
                else { ids[kept] = ids[i]; sizes[kept] = sizes[i]; credits[kept] = credits[i]; used += sizes[kept]; ++kept; }
            }
            resident_count = kept;
        }
        eviction_signature |= evicted_mask << (8 * request);
        ids[resident_count] = id; sizes[resident_count] = size; credits[resident_count] = cost * 12; ++resident_count;
    }
    for (size_t i = 0; i < resident_count; ++i) resident_mask |= UINT64_C(1) << ids[i];
    if (output == NULL || capacity < 40) return -2;
    uint8_t staged[40] = {0};
    store_i64_le(staged, 0, misses); store_i64_le(staged, 8, total_cost);
    store_i64_le(staged, 16, (int64_t)hit_signature); store_i64_le(staged, 24, (int64_t)eviction_signature);
    store_i64_le(staged, 32, (int64_t)resident_mask);
    for (size_t byte = 0; byte < 40; ++byte) output[byte] = staged[byte];
    return 40;
}
