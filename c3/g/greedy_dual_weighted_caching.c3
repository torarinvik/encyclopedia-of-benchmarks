module greedy_dual_weighted_caching;

const usz MAX_REQUESTS = 7;
const usz MAX_FILES = 8;
const usz MAX_INPUT = 16;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long greedy_dual_weighted_caching(long* input, usz length, char* output, usz output_capacity)
    @export("greedy_dual_weighted_caching") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long cache_capacity = input[0], count_value = input[1];
    if (cache_capacity < 1 || cache_capacity > 8 || count_value < 0 || count_value > (long)MAX_REQUESTS ||
        length != 2 + 2 * (usz)count_value) return -1;
    long[MAX_FILES] known_cost = zeroed;
    bool[MAX_FILES] seen = zeroed;
    for (usz request = 0; request < (usz)count_value; request++) {
        long id = input[2 + 2 * request], cost = input[3 + 2 * request];
        if (id < 0 || id >= (long)MAX_FILES || cost < 0 || cost > 20) return -1;
        if (seen[(usz)id] && known_cost[(usz)id] != cost) return -1;
        seen[(usz)id] = true;
        known_cost[(usz)id] = cost;
    }
    long[MAX_FILES] ids = zeroed, credits = zeroed;
    usz resident_count = 0;
    long misses = 0, total_cost = 0;
    ulong hit_signature = 0, eviction_signature = 0, resident_mask = 0;
    for (usz request = 0; request < (usz)count_value; request++) {
        long id = input[2 + 2 * request], cost = input[3 + 2 * request];
        usz position = 0;
        while (position < resident_count && ids[position] != id) position++;
        if (position < resident_count) {
            hit_signature |= 1ul << request;
            credits[position] = cost;
            continue;
        }
        misses++; total_cost += cost;
        ulong evicted_mask = 0;
        while (resident_count >= (usz)cache_capacity) {
            long delta = credits[0];
            for (usz i = 1; i < resident_count; i++) if (credits[i] < delta) delta = credits[i];
            usz kept = 0;
            for (usz i = 0; i < resident_count; i++) {
                credits[i] -= delta;
                if (credits[i] == 0) evicted_mask |= 1ul << (usz)ids[i];
                else { ids[kept] = ids[i]; credits[kept] = credits[i]; kept++; }
            }
            resident_count = kept;
        }
        eviction_signature |= evicted_mask << (8 * request);
        ids[resident_count] = id; credits[resident_count] = cost; resident_count++;
    }
    for (usz i = 0; i < resident_count; i++) resident_mask |= 1ul << (usz)ids[i];
    if (output == null || output_capacity < 40) return -2;
    char[40] staged = zeroed;
    store_i64_le(&staged[0], 0, misses);
    store_i64_le(&staged[0], 8, total_cost);
    store_i64_le(&staged[0], 16, (long)hit_signature);
    store_i64_le(&staged[0], 24, (long)eviction_signature);
    store_i64_le(&staged[0], 32, (long)resident_mask);
    for (usz byte = 0; byte < 40; byte++) output[byte] = staged[byte];
    return 40;
}
