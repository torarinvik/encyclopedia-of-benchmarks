#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_Q 64
#define MAX_INPUT (3 * MAX_N + 5 * MAX_Q + 1)
#define MAX_VALUE INT64_C(1000)

typedef struct {
    int child[2];
    int parent;
    int reversed;
    int64_t value;
    int64_t virtual_sum;
    int64_t sum;
} Node;

static int is_aux_root(const Node *nodes, int x) {
    int p = nodes[x].parent;
    return p < 0 || (nodes[p].child[0] != x && nodes[p].child[1] != x);
}

static int64_t node_sum(const Node *nodes, int x) {
    return x < 0 ? 0 : nodes[x].sum;
}

static void pull(Node *nodes, int x) {
    nodes[x].sum = nodes[x].value + nodes[x].virtual_sum
                 + node_sum(nodes, nodes[x].child[0])
                 + node_sum(nodes, nodes[x].child[1]);
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
        int old_right = nodes[y].child[1];
        nodes[y].virtual_sum += node_sum(nodes, old_right) - node_sum(nodes, last);
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
    access(nodes, v);
    nodes[u].parent = v;
    nodes[v].virtual_sum += nodes[u].sum;
    pull(nodes, v);
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

static int64_t subtree_side_sum(Node *nodes, int vertex, int parent) {
    make_root(nodes, parent);
    access(nodes, vertex);
    if (nodes[vertex].child[0] != parent || nodes[parent].child[1] >= 0) return -1;
    return nodes[vertex].value + nodes[vertex].virtual_sum;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t dynamic_tree_vertex_add_subtree_sum(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 3 * n + 5 * q) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[2 + i] < 0 || input[2 + i] > MAX_VALUE) return -1;

    size_t edge_start = 2 + n, operation_start = edge_start + 2 * (n - 1);
    for (size_t i = 0; i < n - 1; ++i) {
        int64_t u = input[edge_start + 2 * i], v = input[edge_start + 2 * i + 1];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value || u == v) return -1;
    }
    size_t query_count = 0;
    for (size_t i = 0; i < q; ++i) {
        size_t at = operation_start + 5 * i;
        int64_t kind = input[at], a = input[at + 1], b = input[at + 2];
        int64_t c = input[at + 3], d = input[at + 4];
        if (kind == 0) {
            if (a < 0 || a >= n_value || b < 0 || b >= n_value || c < 0 || c >= n_value ||
                d < 0 || d >= n_value || a == b || c == d) return -1;
        } else if (kind == 1) {
            if (a < 0 || a >= n_value || b < 0 || b > MAX_VALUE || c != 0 || d != 0) return -1;
        } else if (kind == 2) {
            if (a < 0 || a >= n_value || b < 0 || b >= n_value || c != 0 || d != 0) return -1;
            ++query_count;
        } else return -1;
    }

    Node nodes[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        nodes[i].child[0] = nodes[i].child[1] = nodes[i].parent = -1;
        nodes[i].reversed = 0;
        nodes[i].value = input[2 + i];
        nodes[i].virtual_sum = 0;
        nodes[i].sum = nodes[i].value;
    }
    for (size_t i = 0; i < n - 1; ++i)
        if (!link_nodes(nodes, (int)input[edge_start + 2 * i], (int)input[edge_start + 2 * i + 1])) return -1;

    int64_t answers[MAX_Q];
    size_t answer_count = 0;
    for (size_t i = 0; i < q; ++i) {
        size_t at = operation_start + 5 * i;
        int kind = (int)input[at];
        int a = (int)input[at + 1], b = (int)input[at + 2];
        if (kind == 0) {
            int c = (int)input[at + 3], d = (int)input[at + 4];
            if (!cut_nodes(nodes, a, b) || !link_nodes(nodes, c, d)) return -1;
        } else if (kind == 1) {
            access(nodes, a);
            nodes[a].value += b;
            pull(nodes, a);
        } else {
            int64_t answer = subtree_side_sum(nodes, a, b);
            if (answer < 0) return -1;
            answers[answer_count++] = answer;
        }
    }

    size_t output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (output == NULL || capacity < output_bytes)) return -2;
    for (size_t i = 0; i < answer_count; ++i) put_i64_le(output, 8 * i, answers[i]);
    (void)query_count;
    return (int64_t)output_bytes;
}
