#include <stddef.h>
#include <stdint.h>

#define MAX_N 256
#define MAX_Q 512
#define MAX_INPUT 2306
#define OFFSET INT64_C(1000001)

static void build(size_t node, size_t left, size_t right, const int64_t *values,
                  int64_t tree[1024]) {
    if (left == right) { tree[node] = values[left]; return; }
    const size_t mid = left + (right - left) / 2;
    build(node * 2, left, mid, values, tree);
    build(node * 2 + 1, mid + 1, right, values, tree);
    tree[node] = tree[node * 2] > tree[node * 2 + 1] ? tree[node * 2] : tree[node * 2 + 1];
}

static void push(size_t node, size_t left, size_t right, int64_t tree[1024],
                 int64_t lazy[1024], unsigned char pending[1024]) {
    if (!pending[node]) return;
    tree[node] = lazy[node];
    pending[node] = 0;
    if (left != right) {
        const size_t a = node * 2, b = a + 1;
        lazy[a] = lazy[b] = tree[node];
        pending[a] = pending[b] = 1;
    }
}

static void assign_range(size_t node, size_t left, size_t right, size_t ql, size_t qr,
                         int64_t value, int64_t tree[1024], int64_t lazy[1024],
                         unsigned char pending[1024]) {
    push(node, left, right, tree, lazy, pending);
    if (right < ql || left > qr) return;
    if (ql <= left && right <= qr) {
        tree[node] = value;
        if (left != right) {
            const size_t a = node * 2, b = a + 1;
            lazy[a] = lazy[b] = value;
            pending[a] = pending[b] = 1;
        }
        return;
    }
    const size_t mid = left + (right - left) / 2;
    assign_range(node * 2, left, mid, ql, qr, value, tree, lazy, pending);
    assign_range(node * 2 + 1, mid + 1, right, ql, qr, value, tree, lazy, pending);
    tree[node] = tree[node * 2] > tree[node * 2 + 1] ? tree[node * 2] : tree[node * 2 + 1];
}

static int64_t range_max(size_t node, size_t left, size_t right, size_t ql, size_t qr,
                         int64_t tree[1024], int64_t lazy[1024], unsigned char pending[1024]) {
    push(node, left, right, tree, lazy, pending);
    if (right < ql || left > qr) return INT64_MIN;
    if (ql <= left && right <= qr) return tree[node];
    const size_t mid = left + (right - left) / 2;
    const int64_t a = range_max(node * 2, left, mid, ql, qr, tree, lazy, pending);
    const int64_t b = range_max(node * 2 + 1, mid + 1, right, ql, qr, tree, lazy, pending);
    return a > b ? a : b;
}

int64_t lazy_segment_tree_range_set_max(const int64_t *packed, size_t length) {
    if (packed == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t nv = packed[0], qv = packed[1];
    if (nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q) return -1;
    const size_t n = (size_t)nv, q = (size_t)qv;
    if (length < 2 + n) return -1;
    int64_t initial[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        initial[i] = packed[2 + i];
        if (initial[i] < -1000000 || initial[i] > 1000000) return -1;
    }
    size_t offset = 2 + n;
    unsigned char opcode[MAX_Q];
    size_t left[MAX_Q], right[MAX_Q];
    int64_t assigned[MAX_Q];
    for (size_t i = 0; i < q; ++i) {
        if (offset >= length) return -1;
        const int64_t op = packed[offset];
        const size_t width = op == 0 ? 3 : op == 1 ? 4 : 0;
        if (width == 0 || offset + width > length) return -1;
        const int64_t l = packed[offset + 1], r = packed[offset + 2];
        if (l < 0 || l >= r || r > nv) return -1;
        opcode[i] = (unsigned char)op;
        left[i] = (size_t)l;
        right[i] = (size_t)r;
        assigned[i] = 0;
        if (op == 1) {
            assigned[i] = packed[offset + 3];
            if (assigned[i] < -1000000 || assigned[i] > 1000000) return -1;
        }
        offset += width;
    }
    if (offset != length) return -1;
    int64_t tree[1024] = {0}, lazy[1024] = {0};
    unsigned char pending[1024] = {0};
    build(1, 0, n - 1, initial, tree);
    int64_t checksum = 0, query_ordinal = 0;
    for (size_t i = 0; i < q; ++i) {
        const size_t ql = left[i], qr = right[i] - 1;
        if (opcode[i] == 1) assign_range(1, 0, n - 1, ql, qr, assigned[i], tree, lazy, pending);
        else {
            const int64_t answer = range_max(1, 0, n - 1, ql, qr, tree, lazy, pending);
            ++query_ordinal;
            checksum += query_ordinal * (answer + OFFSET);
        }
    }
    return checksum;
}
