#include <stddef.h>
#include <stdint.h>

enum { EHT_OPS = 40, EHT_WORDS = 82, EHT_KEYS = 256, EHT_DEPTH = 8 };

static int eht_find(uint8_t keys[EHT_KEYS][2], const uint8_t counts[EHT_KEYS],
                    int bucket, int key) {
    for (int i = 0; i < counts[bucket]; ++i)
        if (keys[bucket][i] == key) return i;
    return -1;
}

static int eht_split(uint8_t directory[EHT_KEYS], uint8_t keys[EHT_KEYS][2],
                     uint8_t counts[EHT_KEYS], uint8_t depths[EHT_KEYS],
                     uint8_t active[EHT_KEYS], int bucket, int *global_depth,
                     int *high_depth, int *bucket_count) {
    const int depth = depths[bucket];
    if (depth >= EHT_DEPTH) return 0;
    if (depth == *global_depth) {
        const int old_size = 1 << *global_depth;
        for (int i = 0; i < old_size; ++i) directory[i + old_size] = directory[i];
        ++*global_depth;
        if (*global_depth > *high_depth) *high_depth = *global_depth;
    }
    int fresh = 0;
    while (fresh < EHT_KEYS && active[fresh]) ++fresh;
    if (fresh == EHT_KEYS) return 0;
    active[fresh] = 1;
    depths[bucket] = depths[fresh] = (uint8_t)(depth + 1);
    const int old_count = counts[bucket];
    uint8_t old_keys[2] = {keys[bucket][0], keys[bucket][1]};
    counts[bucket] = counts[fresh] = 0;
    keys[bucket][0] = keys[bucket][1] = 0;
    keys[fresh][0] = keys[fresh][1] = 0;
    const int bit = 1 << depth;
    const int size = 1 << *global_depth;
    for (int i = 0; i < size; ++i)
        if (directory[i] == bucket && (i & bit) != 0) directory[i] = (uint8_t)fresh;
    for (int i = 0; i < old_count; ++i) {
        const int target = (old_keys[i] & bit) != 0 ? fresh : bucket;
        keys[target][counts[target]++] = old_keys[i];
    }
    ++*bucket_count;
    return 1;
}

static void eht_coalesce(uint8_t directory[EHT_KEYS], uint8_t keys[EHT_KEYS][2],
                         uint8_t counts[EHT_KEYS], uint8_t depths[EHT_KEYS],
                         uint8_t active[EHT_KEYS], int *bucket_count,
                         int *global_depth, int bucket) {
    while (depths[bucket] > 1) {
        const int depth = depths[bucket];
        const int size = 1 << *global_depth;
        int representative = -1;
        for (int i = 0; i < size; ++i) if (directory[i] == bucket) { representative = i; break; }
        if (representative < 0) break;
        const int mask = (1 << depth) - 1;
        const int prefix = representative & mask;
        const int buddy_prefix = prefix ^ (1 << (depth - 1));
        const int buddy = directory[buddy_prefix];
        if (buddy == bucket || !active[buddy] || depths[buddy] != depth ||
            counts[bucket] + counts[buddy] > 2) break;
        const int survivor = buddy_prefix < prefix ? buddy : bucket;
        const int removed = survivor == bucket ? buddy : bucket;
        for (int i = 0; i < counts[removed]; ++i)
            keys[survivor][counts[survivor] + i] = keys[removed][i];
        counts[survivor] = (uint8_t)(counts[survivor] + counts[removed]);
        counts[removed] = 0;
        keys[removed][0] = keys[removed][1] = 0;
        depths[survivor] = (uint8_t)(depth - 1);
        active[removed] = 0;
        for (int i = 0; i < size; ++i)
            if (directory[i] == removed) directory[i] = (uint8_t)survivor;
        --*bucket_count;
        bucket = survivor;
    }
    while (*global_depth > 1) {
        const int half = 1 << (*global_depth - 1);
        int mirrors = 1;
        for (int i = 0; i < half; ++i)
            if (directory[i] != directory[i + half]) { mirrors = 0; break; }
        if (!mirrors) break;
        --*global_depth;
    }
}

int64_t extendible_hashing_trace(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > EHT_WORDS) return -1;
    const int64_t q64 = input[0];
    if (q64 < 0 || q64 > EHT_OPS || length != 1 + 2 * (size_t)q64) return -1;
    const int q = (int)q64;
    for (int i = 0; i < q; ++i) {
        const int64_t op = input[1 + 2 * i], key = input[2 + 2 * i];
        if (op < 0 || op > 2 || key < 0 || key >= EHT_KEYS) return -1;
    }

    uint8_t directory[EHT_KEYS] = {0};
    uint8_t keys[EHT_KEYS][2] = {{0}};
    uint8_t counts[EHT_KEYS] = {0}, depths[EHT_KEYS] = {0}, active[EHT_KEYS] = {0};
    directory[0] = 0; directory[1] = 1;
    active[0] = active[1] = 1; depths[0] = depths[1] = 1;
    int global_depth = 1, high_depth = 1, bucket_count = 2, live = 0;
    uint64_t successes = 0;
    for (int i = 0; i < q; ++i) {
        const int op = (int)input[1 + 2 * i], key = (int)input[2 + 2 * i];
        int bucket = directory[key & ((1 << global_depth) - 1)];
        const int slot = eht_find(keys, counts, bucket, key);
        int success = 0;
        if (op == 0 && slot < 0) {
            while (counts[bucket] == 2) {
                if (!eht_split(directory, keys, counts, depths, active, bucket,
                               &global_depth, &high_depth, &bucket_count)) break;
                bucket = directory[key & ((1 << global_depth) - 1)];
            }
            if (counts[bucket] < 2) {
                keys[bucket][counts[bucket]++] = (uint8_t)key;
                ++live; success = 1;
            }
        } else if (op == 1 && slot >= 0) {
            --counts[bucket];
            keys[bucket][slot] = keys[bucket][counts[bucket]];
            keys[bucket][counts[bucket]] = 0;
            --live; success = 1;
            eht_coalesce(directory, keys, counts, depths, active, &bucket_count,
                         &global_depth, bucket);
        } else if (op == 2) success = slot >= 0;
        successes = (successes << 1) | (uint64_t)success;
    }
    return (int64_t)(successes | ((uint64_t)bucket_count << 40) |
                     ((uint64_t)global_depth << 49) | ((uint64_t)high_depth << 53) |
                     ((uint64_t)live << 57));
}
