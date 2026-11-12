#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 32
#define MAX_INPUT 163
typedef struct { int left, right, size; int64_t value, sum; uint64_t priority; int reversed; } Node;
typedef struct { int type, left, right; } Operation;

static uint64_t priority_for(size_t index) {
    int64_t state = 1;
    for (size_t i = 0; i <= index; ++i) state = (state * 48271) % INT64_C(2147483647);
    return (uint64_t)state;
}
static int node_size(const Node *t, int x) { return x < 0 ? 0 : t[x].size; }
static int64_t node_sum(const Node *t, int x) { return x < 0 ? 0 : t[x].sum; }
static int higher(const Node *t, int a, int b) {
    return t[a].priority != t[b].priority ? t[a].priority > t[b].priority : a > b;
}
static void pull(Node *t, int x) {
    t[x].size = 1 + node_size(t, t[x].left) + node_size(t, t[x].right);
    t[x].sum = t[x].value + node_sum(t, t[x].left) + node_sum(t, t[x].right);
}
static void apply_reverse(Node *t, int x) {
    if (x < 0) return;
    int tmp = t[x].left; t[x].left = t[x].right; t[x].right = tmp;
    t[x].reversed ^= 1;
}
static void push(Node *t, int x) {
    if (!t[x].reversed) return;
    apply_reverse(t, t[x].left); apply_reverse(t, t[x].right); t[x].reversed = 0;
}
static void split(Node *t, int root, int count, int *first, int *second) {
    if (root < 0) { *first = *second = -1; return; }
    push(t, root);
    if (node_size(t, t[root].left) >= count) {
        int middle, tail;
        split(t, t[root].left, count, &middle, &tail);
        t[root].left = tail; pull(t, root); *first = middle; *second = root;
    } else {
        int middle, tail;
        split(t, t[root].right, count - node_size(t, t[root].left) - 1, &middle, &tail);
        t[root].right = middle; pull(t, root); *first = root; *second = tail;
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
    for (size_t i = 0; i < 8; ++i) out[at + i] = (uint8_t)(bits >> (8 * i));
}

int64_t range_reverse_range_sum(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], q64 = input[1];
    if (n64 < 0 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q) return -1;
    size_t n = (size_t)n64, q = (size_t)q64, offset = 2;
    if (length < 2 + n) return -1;
    Node nodes[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        int64_t value = input[offset++];
        if (value < 0 || value > INT64_C(1000000000)) return -1;
        nodes[i] = (Node){-1, -1, 1, value, value, priority_for(i), 0};
    }
    Operation operations[MAX_Q];
    size_t query_count = 0;
    for (size_t i = 0; i < q; ++i) {
        if (offset + 3 > length) return -1;
        int64_t type = input[offset++], left = input[offset++], right = input[offset++];
        if ((type != 0 && type != 1) || left < 0 || left > right || right > n64) return -1;
        operations[i] = (Operation){(int)type, (int)left, (int)right};
        if (type == 1) ++query_count;
    }
    if (offset != length) return -1;
    int root = -1;
    for (size_t i = 0; i < n; ++i) root = merge(nodes, root, (int)i);
    int64_t answers[MAX_Q]; size_t answer_count = 0;
    for (size_t i = 0; i < q; ++i) {
        Operation op = operations[i]; int prefix, rest, middle, suffix;
        split(nodes, root, op.right, &prefix, &suffix);
        split(nodes, prefix, op.left, &prefix, &middle);
        if (op.type == 0) apply_reverse(nodes, middle);
        else answers[answer_count++] = node_sum(nodes, middle);
        root = merge(nodes, merge(nodes, prefix, middle), suffix);
    }
    size_t bytes = 8 * query_count;
    if (!output || capacity < bytes) return -2;
    for (size_t i = 0; i < query_count; ++i) write_i64_le(output, 8 * i, answers[i]);
    return (int64_t)bytes;
}
