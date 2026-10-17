#include <stddef.h>
#include <stdint.h>

#define MAX_N 64u
#define MAX_Q 64u
#define MAX_INPUT_LENGTH (2u + MAX_N + 4u * MAX_Q + 1u)
#define NODE_CAP 16384u
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

typedef struct {
    int64_t sum;
    int64_t prop;
    int32_t left;
    int32_t right;
} Node;

static int32_t make_node(Node *nodes, size_t *used, int64_t sum, int64_t prop,
                         int32_t left, int32_t right)
{
    if (*used >= NODE_CAP) return -1;
    const int32_t index = (int32_t)(*used);
    nodes[*used] = (Node){sum, prop, left, right};
    ++*used;
    return index;
}

static int32_t clone_node(Node *nodes, size_t *used, int32_t source)
{
    if (source < 0 || *used >= NODE_CAP) return -1;
    const int32_t index = (int32_t)(*used);
    nodes[*used] = nodes[(size_t)source];
    ++*used;
    return index;
}

static int push_lazy(Node *nodes, size_t *used, int32_t node, size_t left, size_t right)
{
    const int64_t prop = nodes[(size_t)node].prop;
    if (prop == 0) return 1;
    nodes[(size_t)node].sum += (int64_t)(right - left + 1u) * prop;
    if (left != right) {
        const int32_t new_left = clone_node(nodes, used, nodes[(size_t)node].left);
        const int32_t new_right = clone_node(nodes, used, nodes[(size_t)node].right);
        if (new_left < 0 || new_right < 0) return 0;
        nodes[(size_t)node].left = new_left;
        nodes[(size_t)node].right = new_right;
        nodes[(size_t)new_left].prop += prop;
        nodes[(size_t)new_right].prop += prop;
    }
    nodes[(size_t)node].prop = 0;
    return 1;
}

static int32_t build(Node *nodes, size_t *used, const int64_t *values,
                     size_t left, size_t right)
{
    if (left == right) return make_node(nodes, used, values[left], 0, -1, -1);
    const size_t mid = left + (right - left) / 2u;
    const int32_t a = build(nodes, used, values, left, mid);
    const int32_t b = build(nodes, used, values, mid + 1u, right);
    if (a < 0 || b < 0) return -1;
    return make_node(nodes, used, nodes[(size_t)a].sum + nodes[(size_t)b].sum, 0, a, b);
}

static int32_t update(Node *nodes, size_t *used, int32_t current,
                      size_t left, size_t right, size_t ql, size_t qr, int64_t delta)
{
    if (!push_lazy(nodes, used, current, left, right)) return -1;
    if (left >= ql && right <= qr) {
        const int32_t copy = clone_node(nodes, used, current);
        if (copy < 0) return -1;
        nodes[(size_t)copy].prop += delta;
        if (!push_lazy(nodes, used, copy, left, right)) return -1;
        return copy;
    }
    if (left > qr || right < ql) return current;

    const int32_t copy = make_node(nodes, used, 0, 0, -1, -1);
    if (copy < 0) return -1;
    const size_t mid = left + (right - left) / 2u;
    const int32_t a = update(nodes, used, nodes[(size_t)current].left,
                             left, mid, ql, qr, delta);
    const int32_t b = update(nodes, used, nodes[(size_t)current].right,
                             mid + 1u, right, ql, qr, delta);
    if (a < 0 || b < 0) return -1;
    nodes[(size_t)copy].left = a;
    nodes[(size_t)copy].right = b;
    nodes[(size_t)copy].sum = nodes[(size_t)a].sum + nodes[(size_t)b].sum;
    return copy;
}

static int64_t query(Node *nodes, size_t *used, int32_t node,
                     size_t left, size_t right, size_t ql, size_t qr, int *ok)
{
    if (!push_lazy(nodes, used, node, left, right)) { *ok = 0; return 0; }
    if (right < ql || qr < left) return 0;
    if (ql <= left && right <= qr) return nodes[(size_t)node].sum;
    const size_t mid = left + (right - left) / 2u;
    const int64_t a = query(nodes, used, nodes[(size_t)node].left,
                            left, mid, ql, qr, ok);
    if (!*ok) return 0;
    const int64_t b = query(nodes, used, nodes[(size_t)node].right,
                            mid + 1u, right, ql, qr, ok);
    return a + b;
}

static uint64_t hash_word(uint64_t hash, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (unsigned shift = 0; shift < 64u; shift += 8u)
        hash = (hash ^ (uint8_t)(bits >> shift)) * FNV_PRIME;
    return hash;
}

int64_t persistent_seg_tree_lazy_prop(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > (int64_t)MAX_N || q64 < 0 || q64 > (int64_t)MAX_Q) return -1;
    const size_t n = (size_t)n64, q = (size_t)q64;
    if (length != 2u + n + 4u * q) return -1;

    int64_t values[MAX_N];
    for (size_t index = 0; index < n; ++index) {
        values[index] = input[2u + index];
        if (values[index] < -1000 || values[index] > 1000) return -1;
    }

    Node nodes[NODE_CAP];
    size_t used = 0;
    int32_t roots[MAX_Q + 1u];
    roots[0] = build(nodes, &used, values, 0, n - 1u);
    if (roots[0] < 0) return -1;
    size_t version_count = 1u, query_count = 0u, offset = 2u + n;
    int64_t query_sums[MAX_Q];

    for (size_t operation_index = 0; operation_index < q; ++operation_index, offset += 4u) {
        const int64_t op = input[offset], a = input[offset + 1u];
        const int64_t b = input[offset + 2u], c = input[offset + 3u];
        if (op == 0) {
            if (a < 0 || a > b || b >= n64 || c < -1000 || c > 1000) return -1;
            const int32_t next = update(nodes, &used, roots[version_count - 1u],
                                        0, n - 1u, (size_t)a, (size_t)b, c);
            if (next < 0) return -1;
            roots[version_count++] = next;
        } else if (op == 1) {
            if (a < 0 || (uint64_t)a >= version_count || b < 0 || c < b || c >= n64) return -1;
            int ok = 1;
            query_sums[query_count] = query(nodes, &used, roots[(size_t)a],
                                            0, n - 1u, (size_t)b, (size_t)c, &ok);
            if (!ok) return -1;
            ++query_count;
        } else {
            return -1;
        }
    }

    uint64_t hash = hash_word(FNV_OFFSET, (int64_t)version_count);
    hash = hash_word(hash, (int64_t)query_count);
    for (size_t index = 0; index < query_count; ++index) hash = hash_word(hash, query_sums[index]);
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
