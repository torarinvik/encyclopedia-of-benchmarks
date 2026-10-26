module landlord_file_caching;

const usz MAX_REQUESTS = 7;
const usz MAX_FILES = 8;
const usz MAX_INPUT = 23;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long landlord_file_caching(long* input, usz length, char* output, usz capacity) @export("landlord_file_caching") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long capacity_value = input[0], count_value = input[1];
    if (capacity_value < 1 || capacity_value > 8 || count_value < 0 || count_value > (long)MAX_REQUESTS ||
        length != 2 + 3 * (usz)count_value) return -1;
    long[MAX_FILES] known_size = zeroed, known_cost = zeroed;
    bool[MAX_FILES] seen = zeroed;
    for (usz request = 0; request < (usz)count_value; request += 1) {
        long id = input[2 + 3 * request], size = input[3 + 3 * request], cost = input[4 + 3 * request];
        if (id < 0 || id >= (long)MAX_FILES || size < 1 || size > 4 || size > capacity_value || cost < 0 || cost > 20) return -1;
        if (seen[(usz)id] && (known_size[(usz)id] != size || known_cost[(usz)id] != cost)) return -1;
        seen[(usz)id] = true; known_size[(usz)id] = size; known_cost[(usz)id] = cost;
    }
    long[MAX_FILES] ids = zeroed, sizes = zeroed, credits = zeroed;
    usz resident_count = 0;
    long misses = 0, total_cost = 0;
    ulong hit_signature = 0, eviction_signature = 0, resident_mask = 0;
    for (usz request = 0; request < (usz)count_value; request += 1) {
        long id = input[2 + 3 * request], size = input[3 + 3 * request], cost = input[4 + 3 * request];
        usz position = 0;
        while (position < resident_count && ids[position] != id) position += 1;
        if (position < resident_count) { hit_signature |= 1ul << request; continue; }
        misses += 1; total_cost += cost;
        ulong evicted_mask = 0;
        long used = 0;
        for (usz i = 0; i < resident_count; i += 1) used += sizes[i];
        while (used + size > capacity_value) {
            long delta = credits[0] / sizes[0];
            for (usz i = 1; i < resident_count; i += 1) {
                long ratio = credits[i] / sizes[i];
                if (ratio < delta) delta = ratio;
            }
            usz kept = 0;
            used = 0;
            for (usz i = 0; i < resident_count; i += 1) {
                credits[i] -= delta * sizes[i];
                if (credits[i] == 0) evicted_mask |= 1ul << (usz)ids[i];
                else {
                    ids[kept] = ids[i]; sizes[kept] = sizes[i]; credits[kept] = credits[i];
                    used += sizes[kept]; kept += 1;
                }
            }
            resident_count = kept;
        }
        eviction_signature |= evicted_mask << (8 * request);
        ids[resident_count] = id; sizes[resident_count] = size; credits[resident_count] = cost * 12; resident_count += 1;
    }
    for (usz i = 0; i < resident_count; i += 1) resident_mask |= 1ul << (usz)ids[i];
    if (output == null || capacity < 40) return -2;
    char[40] staged = zeroed;
    store_i64_le(&staged[0], 0, misses);
    store_i64_le(&staged[0], 8, total_cost);
    store_i64_le(&staged[0], 16, (long)hit_signature);
    store_i64_le(&staged[0], 24, (long)eviction_signature);
    store_i64_le(&staged[0], 32, (long)resident_mask);
    for (usz byte = 0; byte < 40; byte += 1) output[byte] = staged[byte];
    return 40;
}
