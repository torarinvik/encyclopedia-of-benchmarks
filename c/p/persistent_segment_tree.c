#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 64
#define MAX_INPUT 322
#define NODE_CAP 640
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

typedef struct { int64_t sum; int32_t left, right; } Node;

static int32_t make_node(Node *nodes, size_t *used, int64_t sum, int32_t left, int32_t right) {
    if (*used >= NODE_CAP) return -1;
    const int32_t result = (int32_t)(*used);
    nodes[*used] = (Node){sum, left, right};
    ++*used;
    return result;
}

static int32_t build(Node *nodes, size_t *used, const int64_t *values, size_t left, size_t right) {
    if (left == right) return make_node(nodes, used, values[left], -1, -1);
    const size_t mid = left + (right - left) / 2;
    const int32_t a = build(nodes, used, values, left, mid);
    const int32_t b = build(nodes, used, values, mid + 1, right);
    if (a < 0 || b < 0) return -1;
    return make_node(nodes, used, nodes[a].sum + nodes[b].sum, a, b);
}

static int32_t point_set(Node *nodes, size_t *used, int32_t root, size_t left, size_t right,
                         size_t index, int64_t value) {
    if (left == right) return make_node(nodes, used, value, -1, -1);
    const size_t mid = left + (right - left) / 2;
    int32_t a = nodes[root].left, b = nodes[root].right;
    if (index <= mid) a = point_set(nodes, used, a, left, mid, index, value);
    else b = point_set(nodes, used, b, mid + 1, right, index, value);
    if (a < 0 || b < 0) return -1;
    return make_node(nodes, used, nodes[a].sum + nodes[b].sum, a, b);
}

static int64_t range_sum(const Node *nodes, int32_t node, size_t left, size_t right,
                         size_t ql, size_t qr) {
    if (ql <= left && right <= qr) return nodes[node].sum;
    const size_t mid = left + (right - left) / 2;
    int64_t total = 0;
    if (ql <= mid) total += range_sum(nodes, nodes[node].left, left, mid, ql, qr);
    if (qr > mid) total += range_sum(nodes, nodes[node].right, mid + 1, right, ql, qr);
    return total;
}

static uint64_t hash_word(uint64_t hash, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (unsigned shift = 0; shift < 64; shift += 8)
        hash = (hash ^ (uint8_t)(bits >> shift)) * FNV_PRIME;
    return hash;
}

int64_t persistent_segment_tree(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q) return -1;
    const size_t n = (size_t)n64, q = (size_t)q64;
    if (length != 2 + n + 4 * q) return -1;
    int64_t values[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        values[i] = input[2 + i];
        if (values[i] < -1000 || values[i] > 1000) return -1;
    }
    Node nodes[NODE_CAP]; size_t used = 0;
    int32_t roots[MAX_Q + 1];
    roots[0] = build(nodes, &used, values, 0, n - 1);
    if (roots[0] < 0) return -1;
    size_t version_count = 1, query_count = 0, offset = 2 + n;
    int64_t query_sums[MAX_Q];
    for (size_t i = 0; i < q; ++i, offset += 4) {
        const int64_t op = input[offset], a = input[offset + 1], b = input[offset + 2], c = input[offset + 3];
        if (op == 0) {
            if (a < 0 || (uint64_t)a >= version_count || b < 0 || b >= n64 || c < -1000 || c > 1000) return -1;
            const int32_t next = point_set(nodes, &used, roots[a], 0, n - 1, (size_t)b, c);
            if (next < 0) return -1;
            roots[version_count++] = next;
        } else if (op == 1) {
            if (a < 0 || (uint64_t)a >= version_count || b < 0 || c < b || c >= n64) return -1;
            query_sums[query_count++] = range_sum(nodes, roots[a], 0, n - 1, (size_t)b, (size_t)c);
        } else return -1;
    }
    uint64_t hash = FNV_OFFSET;
    hash = hash_word(hash, (int64_t)version_count);
    hash = hash_word(hash, (int64_t)query_count);
    for (size_t i = 0; i < query_count; ++i) hash = hash_word(hash, query_sums[i]);
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
