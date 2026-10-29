#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_Q 64
#define MAX_INPUT (2 + MAX_N + 3 * MAX_Q)

typedef struct {
    int child[2];
    int parent;
    int reversed;
    int64_t value;
    int64_t sum;
} Node;

static int is_aux_root(const Node *nodes, int x) {
    int p = nodes[x].parent;
    return p < 0 || (nodes[p].child[0] != x && nodes[p].child[1] != x);
}

static void pull(Node *nodes, int x) {
    int left = nodes[x].child[0], right = nodes[x].child[1];
    nodes[x].sum = nodes[x].value + (left < 0 ? 0 : nodes[left].sum)
                                 + (right < 0 ? 0 : nodes[right].sum);
}

static void toggle_reverse(Node *nodes, int x) {
    if (x < 0) return;
    int tmp = nodes[x].child[0];
    nodes[x].child[0] = nodes[x].child[1];
    nodes[x].child[1] = tmp;
    nodes[x].reversed ^= 1;
}

static void push(Node *nodes, int x) {
    if (!nodes[x].reversed) return;
    toggle_reverse(nodes, nodes[x].child[0]);
    toggle_reverse(nodes, nodes[x].child[1]);
    nodes[x].reversed = 0;
}

static void rotate(Node *nodes, int x) {
    int p = nodes[x].parent, g = nodes[p].parent;
    int direction = nodes[p].child[1] == x;
    int middle = nodes[x].child[direction ^ 1];
    if (!is_aux_root(nodes, p)) nodes[g].child[nodes[g].child[1] == p] = x;
    nodes[x].parent = g;
    nodes[x].child[direction ^ 1] = p;
    nodes[p].parent = x;
    nodes[p].child[direction] = middle;
    if (middle >= 0) nodes[middle].parent = p;
    pull(nodes, p);
    pull(nodes, x);
}

static void splay(Node *nodes, int x) {
    int stack[MAX_N], count = 0, y = x;
    stack[count++] = y;
    while (!is_aux_root(nodes, y)) {
        y = nodes[y].parent;
        stack[count++] = y;
    }
    while (count > 0) push(nodes, stack[--count]);
    while (!is_aux_root(nodes, x)) {
        int p = nodes[x].parent;
        if (!is_aux_root(nodes, p)) {
            int g = nodes[p].parent;
            int zigzig = (nodes[p].child[0] == x) == (nodes[g].child[0] == p);
            rotate(nodes, zigzig ? p : x);
        }
        rotate(nodes, x);
    }
}

static void access(Node *nodes, int x) {
    int last = -1;
    for (int y = x; y >= 0; y = nodes[y].parent) {
        splay(nodes, y);
        nodes[y].child[1] = last;
        if (last >= 0) nodes[last].parent = y;
        pull(nodes, y);
        last = y;
    }
    splay(nodes, x);
}

static void make_root(Node *nodes, int x) {
    access(nodes, x);
    toggle_reverse(nodes, x);
}

static int find_root(Node *nodes, int x) {
    access(nodes, x);
    push(nodes, x);
    while (nodes[x].child[0] >= 0) {
        x = nodes[x].child[0];
        push(nodes, x);
    }
    splay(nodes, x);
    return x;
}

static int link_nodes(Node *nodes, int u, int v) {
    if (u == v) return 0;
    make_root(nodes, u);
    if (find_root(nodes, v) == u) return 0;
    nodes[u].parent = v;
    return 1;
}

static int cut_nodes(Node *nodes, int u, int v) {
    if (u == v) return 0;
    make_root(nodes, u);
    access(nodes, v);
    if (nodes[v].child[0] != u || nodes[u].child[1] >= 0) return 0;
    nodes[v].child[0] = -1;
    nodes[u].parent = -1;
    pull(nodes, v);
    return 1;
}

static int64_t path_sum(Node *nodes, int u, int v) {
    make_root(nodes, u);
    if (find_root(nodes, v) != u) return -1;
    make_root(nodes, u);
    access(nodes, v);
    return nodes[v].sum;
}

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t link_cut_tree(const int64_t *input, size_t input_length,
                      uint8_t *output, size_t output_capacity) {
    if (!input || input_length < 2 || input_length > MAX_INPUT) return -1;
    int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    size_t n = (size_t)n_value, q = (size_t)q_value;
    if (input_length != 2 + n + 3 * q) return -1;
    for (size_t vertex = 0; vertex < n; ++vertex)
        if (input[2 + vertex] < 0 || input[2 + vertex] > 1000000) return -1;
    size_t operations_at = 2 + n;
    for (size_t i = 0; i < q; ++i) {
        int64_t op = input[operations_at + 3 * i];
        int64_t u = input[operations_at + 3 * i + 1];
        int64_t v = input[operations_at + 3 * i + 2];
        if (op < 0 || op > 2 || u < 0 || u >= n_value || v < 0 || v >= n_value) return -1;
    }
    if (!output || output_capacity < 8 * q) return -2;

    Node nodes[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        nodes[i].child[0] = nodes[i].child[1] = nodes[i].parent = -1;
        nodes[i].reversed = 0;
        nodes[i].value = input[2 + i];
        nodes[i].sum = nodes[i].value;
    }
    for (size_t i = 0; i < q; ++i) {
        size_t at = operations_at + 3 * i;
        int op = (int)input[at], u = (int)input[at + 1], v = (int)input[at + 2];
        int64_t result = op == 0 ? link_nodes(nodes, u, v)
                        : op == 1 ? cut_nodes(nodes, u, v)
                                  : path_sum(nodes, u, v);
        put_i64(output, 8 * i, result);
    }
    return (int64_t)(8 * q);
}
