#include <stddef.h>
#include <stdint.h>

enum { HH_MAX_BUCKETS = 8, HH_MAX_OPS = 64, HH_MAX_INPUT = 132, HH_MAX_OUTPUT = 520 };

static int hh_less(uint8_t ka, uint8_t ia, uint8_t kb, uint8_t ib) {
    return ka < kb || (ka == kb && ia < ib);
}

static void hh_swap(uint8_t keys[HH_MAX_BUCKETS][HH_MAX_OPS],
                    uint8_t ids[HH_MAX_BUCKETS][HH_MAX_OPS],
                    int bucket, int a, int b) {
    uint8_t key = keys[bucket][a];
    uint8_t id = ids[bucket][a];
    keys[bucket][a] = keys[bucket][b];
    ids[bucket][a] = ids[bucket][b];
    keys[bucket][b] = key;
    ids[bucket][b] = id;
}

static void hh_push(uint8_t keys[HH_MAX_BUCKETS][HH_MAX_OPS],
                    uint8_t ids[HH_MAX_BUCKETS][HH_MAX_OPS],
                    uint8_t sizes[HH_MAX_BUCKETS], int bucket,
                    uint8_t key, uint8_t id) {
    int child = sizes[bucket]++;
    keys[bucket][child] = key;
    ids[bucket][child] = id;
    while (child > 0) {
        int parent = (child - 1) / 2;
        if (!hh_less(keys[bucket][child], ids[bucket][child],
                     keys[bucket][parent], ids[bucket][parent])) break;
        hh_swap(keys, ids, bucket, child, parent);
        child = parent;
    }
}

static void hh_pop(uint8_t keys[HH_MAX_BUCKETS][HH_MAX_OPS],
                   uint8_t ids[HH_MAX_BUCKETS][HH_MAX_OPS],
                   uint8_t sizes[HH_MAX_BUCKETS], int bucket) {
    int last = --sizes[bucket];
    if (last == 0) return;
    keys[bucket][0] = keys[bucket][last];
    ids[bucket][0] = ids[bucket][last];
    int parent = 0;
    for (;;) {
        int left = 2 * parent + 1;
        if (left >= sizes[bucket]) break;
        int child = left;
        int right = left + 1;
        if (right < sizes[bucket] && hh_less(keys[bucket][right], ids[bucket][right],
                                             keys[bucket][left], ids[bucket][left])) child = right;
        if (!hh_less(keys[bucket][child], ids[bucket][child],
                     keys[bucket][parent], ids[bucket][parent])) break;
        hh_swap(keys, ids, bucket, child, parent);
        parent = child;
    }
}

static void hh_write_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) out[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t hash_heap_priority_queue_trace(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > HH_MAX_INPUT) return -1;
    int64_t u64 = input[0], b64 = input[1], q64 = input[2];
    if (u64 < 1 || u64 > 128 || b64 < 1 || b64 > 8 || b64 > u64 || q64 < 0 || q64 > HH_MAX_OPS)
        return -1;
    int universe = (int)u64, buckets = (int)b64, q = (int)q64;
    if (length != (size_t)(3 + 2 * q)) return -1;
    uint8_t opcodes[HH_MAX_OPS] = {0};
    uint8_t operands[HH_MAX_OPS] = {0};
    for (int i = 0; i < q; ++i) {
        int64_t op = input[3 + 2 * i], arg = input[4 + 2 * i];
        if (op == 0) {
            if (arg < 0 || arg >= universe) return -1;
        } else if (op == 1 || op == 2) {
            if (arg != 0) return -1;
        } else return -1;
        opcodes[i] = (uint8_t)op;
        operands[i] = (uint8_t)arg;
    }
    uint8_t keys[HH_MAX_BUCKETS][HH_MAX_OPS] = {{0}};
    uint8_t ids[HH_MAX_BUCKETS][HH_MAX_OPS] = {{0}};
    uint8_t sizes[HH_MAX_BUCKETS] = {0};
    uint8_t staged[HH_MAX_OUTPUT] = {0};
    hh_write_i64(staged, 0, q);
    for (int i = 0; i < q; ++i) {
        size_t at = (size_t)(i + 1) * 8;
        if (opcodes[i] == 0) {
            int bucket = ((int)operands[i] * buckets) / universe;
            hh_push(keys, ids, sizes, bucket, operands[i], (uint8_t)i);
            hh_write_i64(staged, at, -2);
            continue;
        }
        int bucket = 0;
        while (bucket < buckets && sizes[bucket] == 0) ++bucket;
        if (bucket == buckets) {
            hh_write_i64(staged, at, -1);
            continue;
        }
        int64_t packed = ((int64_t)ids[bucket][0] << 8) | keys[bucket][0];
        hh_write_i64(staged, at, packed);
        if (opcodes[i] == 2) hh_pop(keys, ids, sizes, bucket);
    }
    size_t bytes = (size_t)(q + 1) * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
