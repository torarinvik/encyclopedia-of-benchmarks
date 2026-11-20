#include <stddef.h>
#include <stdint.h>

#define LINEAR_HASH_MAX_OPERATIONS 63
#define LINEAR_HASH_MAX_BUCKETS 32

static size_t linear_hash_bucket(int64_t key, size_t level, size_t split) {
    const size_t base = (size_t)1 << level;
    int64_t remainder = key % (int64_t)base;
    if (remainder < 0) remainder += (int64_t)base;
    size_t index = (size_t)remainder;
    if (index < split) {
        remainder = key % (int64_t)(base << 1);
        if (remainder < 0) remainder += (int64_t)(base << 1);
        index = (size_t)remainder;
    }
    return index;
}

int64_t linear_hashing_trace(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > 128) return -1;
    const int64_t operation_count = values[0];
    if (operation_count < 0 || operation_count > LINEAR_HASH_MAX_OPERATIONS
        || length != (size_t)(1 + 2 * operation_count)) return -1;

    int32_t heads[LINEAR_HASH_MAX_BUCKETS];
    int64_t keys[LINEAR_HASH_MAX_OPERATIONS];
    int32_t links[LINEAR_HASH_MAX_OPERATIONS];
    for (size_t bucket = 0; bucket < LINEAR_HASH_MAX_BUCKETS; ++bucket) heads[bucket] = -1;

    size_t level = 1;
    size_t split = 0;
    size_t live_count = 0;
    size_t allocated = 0;
    int64_t result = 0;

    for (size_t operation = 0; operation < (size_t)operation_count; ++operation) {
        const int64_t opcode = values[1 + 2 * operation];
        const int64_t key = values[2 + 2 * operation];
        if (opcode < 0 || opcode > 2 || key < -1024 || key > 1023) return -1;

        const size_t bucket = linear_hash_bucket(key, level, split);
        int32_t previous = -1;
        int32_t node = heads[bucket];
        while (node != -1 && keys[node] != key) {
            previous = node;
            node = links[node];
        }
        const int found = node != -1;
        int64_t succeeded = 0;

        if (opcode == 0 && !found) {
            node = (int32_t)allocated;
            ++allocated;
            keys[node] = key;
            links[node] = heads[bucket];
            heads[bucket] = node;
            ++live_count;
            succeeded = 1;

            const size_t base = (size_t)1 << level;
            const size_t bucket_count = base + split;
            if (bucket_count < LINEAR_HASH_MAX_BUCKETS && live_count > 2 * bucket_count) {
                const size_t old_bucket = split;
                const size_t new_bucket = base + split;
                int32_t current = heads[old_bucket];
                heads[old_bucket] = -1;
                while (current != -1) {
                    const int32_t following = links[current];
                    int64_t remainder = keys[current] % (int64_t)(base << 1);
                    if (remainder < 0) remainder += (int64_t)(base << 1);
                    const size_t destination = (size_t)remainder;
                    if (destination == new_bucket) {
                        links[current] = heads[new_bucket];
                        heads[new_bucket] = current;
                    } else {
                        links[current] = heads[old_bucket];
                        heads[old_bucket] = current;
                    }
                    current = following;
                }
                ++split;
                if (split == base) {
                    ++level;
                    split = 0;
                }
            }
        } else if (opcode == 1 && found) {
            if (previous == -1) heads[bucket] = links[node];
            else links[previous] = links[node];
            --live_count;
            succeeded = 1;
        } else if (opcode == 2 && found) {
            succeeded = 1;
        }
        result = (result << 1) | succeeded;
    }
    return result;
}
