#include <stddef.h>
#include <stdint.h>

enum { DOMAIN = 64, MAX_Q = 32, MAX_ROOTS = 33, MAX_NODES = 1024,
       MAX_INPUT = 131, MAX_OUTPUT = 256 };

typedef struct { int32_t left, right; int64_t total; } Node;
typedef struct { int64_t op, a, b, c; } Operation;

static int new_node(Node nodes[MAX_NODES], size_t *used)
{
    if (*used >= MAX_NODES) return -1;
    const int node = (int)(*used)++;
    nodes[node] = (Node){0, 0, 0};
    return node;
}

static int insert(Node nodes[MAX_NODES], size_t *used, int node, int lo, int hi,
                  int value, int amount)
{
    if (node == 0) {
        node = new_node(nodes, used);
        if (node < 0) return -1;
    }
    if (lo == hi) { nodes[node].total += amount; return node; }
    const int mid = (lo + hi) / 2;
    if (value <= mid) {
        const int child = insert(nodes, used, nodes[node].left, lo, mid, value, amount);
        if (child < 0) return -1;
        nodes[node].left = child;
    } else {
        const int child = insert(nodes, used, nodes[node].right, mid + 1, hi, value, amount);
        if (child < 0) return -1;
        nodes[node].right = child;
    }
    nodes[node].total = nodes[nodes[node].left].total + nodes[nodes[node].right].total;
    return node;
}

static int merge_nodes(Node nodes[MAX_NODES], int a, int b, int lo, int hi)
{
    if (a == 0) return b;
    if (b == 0) return a;
    if (lo == hi) { nodes[a].total += nodes[b].total; return a; }
    const int mid = (lo + hi) / 2;
    nodes[a].left = merge_nodes(nodes, nodes[a].left, nodes[b].left, lo, mid);
    nodes[a].right = merge_nodes(nodes, nodes[a].right, nodes[b].right, mid + 1, hi);
    nodes[a].total = nodes[nodes[a].left].total + nodes[nodes[a].right].total;
    return a;
}

static int split(Node nodes[MAX_NODES], size_t *used, int node, int lo, int hi,
                 int ql, int qr, int *moved)
{
    *moved = 0;
    if (node == 0 || qr < lo || hi < ql) return node;
    if (ql <= lo && hi <= qr) { *moved = node; return 0; }
    const int mid = (lo + hi) / 2;
    int moved_left = 0, moved_right = 0;
    const int remain_left = split(nodes, used, nodes[node].left, lo, mid, ql, qr, &moved_left);
    if (remain_left < 0) return -1;
    const int remain_right = split(nodes, used, nodes[node].right, mid + 1, hi, ql, qr, &moved_right);
    if (remain_right < 0) return -1;
    nodes[node].left = remain_left;
    nodes[node].right = remain_right;
    nodes[node].total = nodes[remain_left].total + nodes[remain_right].total;
    if (moved_left != 0 || moved_right != 0) {
        *moved = new_node(nodes, used);
        if (*moved < 0) return -1;
        nodes[*moved].left = moved_left;
        nodes[*moved].right = moved_right;
        nodes[*moved].total = nodes[moved_left].total + nodes[moved_right].total;
    }
    return node;
}

static int64_t range_sum(const Node nodes[MAX_NODES], int node, int lo, int hi, int ql, int qr)
{
    if (node == 0 || qr < lo || hi < ql) return 0;
    if (ql <= lo && hi <= qr) return nodes[node].total;
    const int mid = (lo + hi) / 2;
    return range_sum(nodes, nodes[node].left, lo, mid, ql, qr)
         + range_sum(nodes, nodes[node].right, mid + 1, hi, ql, qr);
}

static int64_t kth(const Node nodes[MAX_NODES], int node, int lo, int hi, int64_t k)
{
    if (node == 0 || k > nodes[node].total) return -1;
    if (lo == hi) return lo;
    const int mid = (lo + hi) / 2;
    const int left = nodes[node].left;
    if (k <= nodes[left].total) return kth(nodes, left, lo, mid, k);
    return kth(nodes, nodes[node].right, mid + 1, hi, k - nodes[left].total);
}

static void pack_i64(uint8_t *buffer, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) buffer[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t segment_tree_merge_split(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT || input[0] != DOMAIN
        || input[1] < 0 || input[1] > MAX_Q || length != 2 + 4 * (size_t)input[1]) return -1;
    const size_t q = (size_t)input[1];
    Operation ops[MAX_Q];
    size_t roots_count = 1;
    for (size_t i = 0; i < q; ++i) {
        const int64_t op = input[2 + 4 * i], a = input[3 + 4 * i];
        const int64_t b = input[4 + 4 * i], c = input[5 + 4 * i];
        if (op == 0) {
            if (a < 0 || (size_t)a >= roots_count || b < 1 || b > DOMAIN || c < 1 || c > 10) return -1;
        } else if (op == 1) {
            if (a < 0 || (size_t)a >= roots_count || b < 1 || c < b || c > DOMAIN || roots_count >= MAX_ROOTS) return -1;
            ++roots_count;
        } else if (op == 2) {
            if (a < 0 || (size_t)a >= roots_count || b < 0 || (size_t)b >= roots_count || a == b || c != 0) return -1;
        } else if (op == 3) {
            if (a < 0 || (size_t)a >= roots_count || b < 1 || c < b || c > DOMAIN) return -1;
        } else if (op == 4) {
            if (a < 0 || (size_t)a >= roots_count || b < 1 || b > MAX_Q * 10 || c != 0) return -1;
        } else return -1;
        ops[i] = (Operation){op, a, b, c};
    }

    Node nodes[MAX_NODES] = {{0, 0, 0}};
    int roots[MAX_ROOTS] = {0};
    size_t used = 1, root_count = 1, output_count = 0;
    uint8_t staged[MAX_OUTPUT] = {0};
    for (size_t i = 0; i < q; ++i) {
        const Operation item = ops[i];
        const size_t a = (size_t)item.a;
        if (item.op == 0) {
            const int updated = insert(nodes, &used, roots[a], 1, DOMAIN, (int)item.b, (int)item.c);
            if (updated < 0) return -1;
            roots[a] = updated;
        } else if (item.op == 1) {
            int moved = 0;
            const int remain = split(nodes, &used, roots[a], 1, DOMAIN, (int)item.b, (int)item.c, &moved);
            if (remain < 0) return -1;
            roots[a] = remain;
            roots[root_count++] = moved;
        } else if (item.op == 2) {
            const size_t b = (size_t)item.b;
            roots[a] = merge_nodes(nodes, roots[a], roots[b], 1, DOMAIN);
            roots[b] = 0;
        } else if (item.op == 3) {
            pack_i64(staged, output_count, range_sum(nodes, roots[a], 1, DOMAIN, (int)item.b, (int)item.c));
            output_count += 8;
        } else {
            pack_i64(staged, output_count, kth(nodes, roots[a], 1, DOMAIN, item.b));
            output_count += 8;
        }
    }
    if (output == NULL || capacity < output_count) return -2;
    for (size_t i = 0; i < output_count; ++i) output[i] = staged[i];
    return (int64_t)output_count;
}
