/* Clean-room compacted-trie delimiter-rank profile for Encyclopedia DOI 639. */
#include <stddef.h>
#include <stdint.h>

#define MAX_KEYS 16
#define MAX_Q 16
#define MAX_NODES (2 * MAX_KEYS - 1)
#define MAX_OUT (3 + 5 * MAX_NODES + MAX_Q)

typedef struct { int bit, left, right; uint32_t key, low, high; int leaves; } Node;
static uint32_t keys[MAX_KEYS];
static Node nodes[MAX_NODES];
static int node_count;

static int build(int lo, int hi, int width) {
    int id = node_count++;
    nodes[id].left = nodes[id].right = -1;
    if (hi - lo == 1) {
        nodes[id].bit = -1; nodes[id].key = keys[lo]; nodes[id].low = nodes[id].high = keys[lo]; nodes[id].leaves = 1;
        return id;
    }
    uint32_t difference = keys[lo] ^ keys[hi - 1];
    int bit = width - 1;
    while (((difference >> bit) & 1u) == 0) --bit;
    int split = lo;
    while (split < hi && ((keys[split] >> bit) & 1u) == 0) ++split;
    nodes[id].bit = width - 1 - bit; nodes[id].key = 0; nodes[id].low = keys[lo]; nodes[id].high = keys[hi - 1];
    nodes[id].left = build(lo, split, width);
    nodes[id].right = build(split, hi, width);
    nodes[id].leaves = nodes[nodes[id].left].leaves + nodes[nodes[id].right].leaves;
    return id;
}
static int rank_key(uint32_t query, int width) {
    int id = 0, rank = 0;
    while (1) {
        if (query < nodes[id].low) return rank;
        if (query > nodes[id].high) return rank + nodes[id].leaves;
        if (nodes[id].bit < 0) return rank;
        int shift = width - 1 - nodes[id].bit;
        if ((query >> shift) & 1u) { rank += nodes[nodes[id].left].leaves; id = nodes[id].right; }
        else id = nodes[id].left;
    }
}
static void put_i64(uint8_t *out, size_t pos, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[pos + b] = (uint8_t)(bits >> (8 * b));
}

int64_t mmpfh_compacted_trie_rank(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (!input || length < 3 || length > 35) return -1;
    int64_t w0 = input[0], d0 = input[1], q0 = input[2];
    if (w0 < 1 || w0 > 16 || d0 < 1 || d0 > MAX_KEYS || q0 < 1 || q0 > MAX_Q ||
        length != 3 + (size_t)d0 + (size_t)q0) return -1;
    uint32_t limit = 1u << (int)w0;
    for (int i = 0; i < (int)d0; ++i) {
        int64_t value = input[3 + i];
        if (value < 0 || (uint64_t)value >= limit || (i && value <= input[2 + i])) return -1;
        keys[i] = (uint32_t)value;
    }
    for (int i = 0; i < (int)q0; ++i) {
        int64_t value = input[3 + (int)d0 + i];
        if (value < 0 || (uint64_t)value >= limit) return -1;
    }
    node_count = 0;
    build(0, (int)d0, (int)w0);
    int64_t staged[MAX_OUT]; size_t used = 0;
    staged[used++] = d0; staged[used++] = node_count; staged[used++] = q0;
    for (int i = 0; i < node_count; ++i) {
        staged[used++] = nodes[i].bit;
        staged[used++] = nodes[i].left;
        staged[used++] = nodes[i].right;
        staged[used++] = nodes[i].low;
        staged[used++] = nodes[i].high;
    }
    for (int i = 0; i < (int)q0; ++i)
        staged[used++] = rank_key((uint32_t)input[3 + (int)d0 + i], (int)w0);
    size_t required = used * 8;
    if (!output || capacity < required) return -2;
    for (size_t i = 0; i < used; ++i) put_i64(output, i * 8, staged[i]);
    return (int64_t)required;
}
