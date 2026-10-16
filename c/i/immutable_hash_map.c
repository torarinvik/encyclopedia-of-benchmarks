#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 256
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_i64(uint64_t hash, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned shift = 0; shift < 64; shift += 8) hash = (hash ^ (uint8_t)(bits >> shift)) * FNV_PRIME;
    return hash;
}

int64_t immutable_hash_map(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 1 + 3 * MAX_OPS) return -1;
    const int64_t count64 = input[0];
    if (count64 < 0 || count64 > MAX_OPS || length != 1 + 3 * (size_t)count64) return -1;
    const size_t count = (size_t)count64;
    int32_t keys[MAX_OPS], values[MAX_OPS];
    int64_t trace[MAX_OPS];
    size_t map_size = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t operation = input[1 + 3 * i];
        const int64_t key64 = input[2 + 3 * i];
        const int64_t value64 = input[3 + 3 * i];
        if (operation < 0 || operation > 3 || key64 < INT32_MIN || key64 > INT32_MAX || value64 < INT32_MIN || value64 > INT32_MAX) return -1;
        const int32_t key = (int32_t)key64;
        const int32_t value = (int32_t)value64;
        if (operation == 0) {
            if (value == 0) return -1;
            keys[map_size] = key;
            values[map_size] = value;
            ++map_size;
            trace[i] = (int64_t)map_size;
        } else if (operation == 1 || operation == 2) {
            int found = 0;
            int32_t found_value = 0;
            for (size_t j = map_size; j > 0; --j) {
                if (keys[j - 1] == key) { found = 1; found_value = values[j - 1]; break; }
            }
            trace[i] = operation == 1 ? found_value : found;
        } else {
            trace[i] = (int64_t)map_size;
        }
    }
    uint64_t hash = hash_i64(FNV_OFFSET, (int64_t)count);
    for (size_t i = 0; i < count; ++i) hash = hash_i64(hash, trace[i]);
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
