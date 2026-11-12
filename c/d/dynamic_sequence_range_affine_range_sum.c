#include <stddef.h>
#include <stdint.h>

#define MOD INT64_C(998244353)
#define MAX_N 32
#define MAX_Q 32
#define MAX_NODES (MAX_N + MAX_Q)
#define MAX_INPUT 195
#define NONE (-1)

typedef struct {
    int left, right, size;
    int64_t value, sum, mul, add;
    uint64_t priority;
    int reversed;
} Node;
typedef struct { int kind, left, right, node; int64_t mul, add; } Operation;

static uint64_t priority_for(size_t id) {
    int64_t state = 1;
    for (size_t i = 0; i <= id; ++i) state = (state * 48271) % INT64_C(2147483647);
    return (uint64_t)state;
}
static int node_size(const Node *t, int x) { return x < 0 ? 0 : t[x].size; }
static int64_t node_sum(const Node *t, int x) { return x < 0 ? 0 : t[x].sum; }
static int higher(const Node *t, int a, int b) {
    return t[a].priority != t[b].priority ? t[a].priority > t[b].priority : a > b;
}
static void pull(Node *t, int x) {
    t[x].size = 1 + node_size(t, t[x].left) + node_size(t, t[x].right);
    t[x].sum = (t[x].value + node_sum(t, t[x].left) + node_sum(t, t[x].right)) % MOD;
}
static void apply_affine(Node *t, int x, int64_t mul, int64_t add) {
    if (x < 0) return;
    t[x].value = (mul * t[x].value + add) % MOD;
    t[x].sum = (mul * t[x].sum + add * t[x].size) % MOD;
    t[x].mul = (mul * t[x].mul) % MOD;
    t[x].add = (mul * t[x].add + add) % MOD;
}
static void apply_reverse(Node *t, int x) {
    if (x < 0) return;
    int child = t[x].left; t[x].left = t[x].right; t[x].right = child;
    t[x].reversed ^= 1;
}
static void push(Node *t, int x) {
    if (t[x].mul != 1 || t[x].add != 0) {
        apply_affine(t, t[x].left, t[x].mul, t[x].add);
        apply_affine(t, t[x].right, t[x].mul, t[x].add);
        t[x].mul = 1; t[x].add = 0;
    }
    if (t[x].reversed) {
        apply_reverse(t, t[x].left); apply_reverse(t, t[x].right); t[x].reversed = 0;
    }
}
static void split(Node *t, int root, int count, int *first, int *second) {
    if (root < 0) { *first = *second = NONE; return; }
    push(t, root);
    if (node_size(t, t[root].left) >= count) {
        int a, b; split(t, t[root].left, count, &a, &b);
        t[root].left = b; pull(t, root); *first = a; *second = root;
    } else {
        int a, b; split(t, t[root].right, count - node_size(t, t[root].left) - 1, &a, &b);
        t[root].right = a; pull(t, root); *first = root; *second = b;
    }
}
static int merge(Node *t, int left, int right) {
    if (left < 0) return right;
    if (right < 0) return left;
    if (higher(t, left, right)) {
        push(t, left); t[left].right = merge(t, t[left].right, right); pull(t, left); return left;
    }
    push(t, right); t[right].left = merge(t, left, t[right].left); pull(t, right); return right;
}
static void write_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t j = 0; j < 8; ++j) out[at + j] = (uint8_t)(bits >> (8 * j));
}

int64_t dynamic_sequence_range_affine_range_sum(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], q64 = input[1];
    if (n64 < 0 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q) return -1;
    size_t n = (size_t)n64, q = (size_t)q64, offset = 2;
    if (length < 2 + n) return -1;
    Node nodes[MAX_NODES] = {0};
    for (size_t i = 0; i < n; ++i) {
        int64_t value = input[offset++];
        if (value < 0 || value >= MOD) return -1;
        nodes[i] = (Node){NONE, NONE, 1, value, value, 1, 0, priority_for(i), 0};
    }
    Operation operations[MAX_Q] = {0};
    size_t current_length = n, node_count = n, query_count = 0;
    for (size_t i = 0; i < q; ++i) {
        if (offset >= length) return -1;
        int64_t kind64 = input[offset++];
        if (kind64 < 0 || kind64 > 4) return -1;
        int kind = (int)kind64;
        Operation op = {kind, 0, 0, NONE, 0, 0};
        if (kind == 0) {
            if (offset + 2 > length) return -1;
            int64_t at = input[offset++], value = input[offset++];
            if (at < 0 || (uint64_t)at > current_length || current_length >= MAX_NODES || value < 0 || value >= MOD) return -1;
            op.left = (int)at; ++current_length;
            op.node = (int)node_count;
            nodes[node_count] = (Node){NONE, NONE, 1, value, value, 1, 0, priority_for(node_count), 0};
            ++node_count;
        } else if (kind == 1) {
            if (offset >= length) return -1;
            int64_t at = input[offset++];
            if (at < 0 || (uint64_t)at >= current_length) return -1;
            op.left = (int)at; --current_length;
        } else if (kind == 2 || kind == 4) {
            if (offset + 2 > length) return -1;
            int64_t left = input[offset++], right = input[offset++];
            if (left < 0 || left > right || (uint64_t)right > current_length) return -1;
            op.left = (int)left; op.right = (int)right;
            if (kind == 4) ++query_count;
        } else {
            if (offset + 4 > length) return -1;
            int64_t left = input[offset++], right = input[offset++], mul = input[offset++], add = input[offset++];
            if (left < 0 || left > right || (uint64_t)right > current_length || mul < 0 || mul >= MOD || add < 0 || add >= MOD) return -1;
            op.left = (int)left; op.right = (int)right; op.mul = mul; op.add = add;
        }
        operations[i] = op;
    }
    if (offset != length) return -1;
    int root = NONE;
    for (size_t i = 0; i < n; ++i) root = merge(nodes, root, (int)i);
    int64_t answers[MAX_Q] = {0}; size_t answer_count = 0;
    for (size_t i = 0; i < q; ++i) {
        Operation op = operations[i]; int prefix, suffix, middle;
        split(nodes, root, op.left, &prefix, &suffix);
        if (op.kind == 0) {
            root = merge(nodes, merge(nodes, prefix, op.node), suffix);
            continue;
        }
        if (op.kind == 1) {
            split(nodes, suffix, 1, &middle, &suffix);
            root = merge(nodes, prefix, suffix);
            continue;
        } else {
            split(nodes, suffix, op.right - op.left, &middle, &suffix);
            if (op.kind == 2) apply_reverse(nodes, middle);
            else if (op.kind == 3) apply_affine(nodes, middle, op.mul, op.add);
            else if (op.kind == 4) answers[answer_count++] = node_sum(nodes, middle);
        }
        root = merge(nodes, merge(nodes, prefix, middle), suffix);
    }
    size_t bytes = 8 * query_count;
    if (!output || capacity < bytes) return -2;
    for (size_t i = 0; i < query_count; ++i) write_i64_le(output, 8 * i, answers[i]);
    return (int64_t)bytes;
}
