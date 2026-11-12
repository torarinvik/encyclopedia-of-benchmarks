#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_Q = 12, MAX_INPUT = 93 };
static const int64_t MODULUS = INT64_C(998244353);

typedef struct { int64_t multiplier, addend; } affine;
typedef struct {
    int child[2], parent;
    bool reversed;
    affine value, forward, backward;
} lct_node;
typedef struct { int64_t kind, a, b, c, d; } query;

static affine identity(void) { return (affine){1, 0}; }
static affine compose(affine after, affine before) {
    return (affine){after.multiplier * before.multiplier % MODULUS,
        (after.multiplier * before.addend + after.addend) % MODULUS};
}

static bool is_aux_root(const lct_node nodes[MAX_N], int x) {
    const int parent = nodes[x].parent;
    return parent < 0 || (nodes[parent].child[0] != x && nodes[parent].child[1] != x);
}

static void pull(lct_node nodes[MAX_N], int x) {
    const lct_node *node = &nodes[x];
    const affine left_forward = node->child[0] < 0 ? identity() : nodes[node->child[0]].forward;
    const affine right_forward = node->child[1] < 0 ? identity() : nodes[node->child[1]].forward;
    const affine left_backward = node->child[0] < 0 ? identity() : nodes[node->child[0]].backward;
    const affine right_backward = node->child[1] < 0 ? identity() : nodes[node->child[1]].backward;
    nodes[x].forward = compose(right_forward, compose(node->value, left_forward));
    nodes[x].backward = compose(left_backward, compose(node->value, right_backward));
}

static void reverse_path(lct_node nodes[MAX_N], int x) {
    if (x < 0) return;
    const int temporary = nodes[x].child[0];
    nodes[x].child[0] = nodes[x].child[1];
    nodes[x].child[1] = temporary;
    const affine aggregate = nodes[x].forward;
    nodes[x].forward = nodes[x].backward;
    nodes[x].backward = aggregate;
    nodes[x].reversed = !nodes[x].reversed;
}

static void push(lct_node nodes[MAX_N], int x) {
    if (!nodes[x].reversed) return;
    reverse_path(nodes, nodes[x].child[0]);
    reverse_path(nodes, nodes[x].child[1]);
    nodes[x].reversed = false;
}

static void rotate(lct_node nodes[MAX_N], int x) {
    const int parent = nodes[x].parent;
    const int grand = nodes[parent].parent;
    const int direction = nodes[parent].child[1] == x;
    const int middle = nodes[x].child[direction ^ 1];
    if (!is_aux_root(nodes, parent))
        nodes[grand].child[nodes[grand].child[1] == parent] = x;
    nodes[x].parent = grand;
    nodes[x].child[direction ^ 1] = parent;
    nodes[parent].parent = x;
    nodes[parent].child[direction] = middle;
    if (middle >= 0) nodes[middle].parent = parent;
    pull(nodes, parent);
    pull(nodes, x);
}

static void splay(lct_node nodes[MAX_N], int x) {
    int stack[MAX_N], count = 0, y = x;
    stack[count++] = y;
    while (!is_aux_root(nodes, y)) { y = nodes[y].parent; stack[count++] = y; }
    while (count > 0) push(nodes, stack[--count]);
    while (!is_aux_root(nodes, x)) {
        const int parent = nodes[x].parent;
        if (!is_aux_root(nodes, parent)) {
            const int grand = nodes[parent].parent;
            const bool zigzig = (nodes[parent].child[0] == x) == (nodes[grand].child[0] == parent);
            rotate(nodes, zigzig ? parent : x);
        }
        rotate(nodes, x);
    }
}

static void access(lct_node nodes[MAX_N], int x) {
    int last = -1;
    for (int y = x; y >= 0;) {
        splay(nodes, y);
        nodes[y].child[1] = last;
        if (last >= 0) nodes[last].parent = y;
        pull(nodes, y);
        last = y;
        y = nodes[y].parent;
    }
    splay(nodes, x);
}

static void make_root(lct_node nodes[MAX_N], int x) { access(nodes, x); reverse_path(nodes, x); }

static int find_root(lct_node nodes[MAX_N], int x) {
    access(nodes, x);
    push(nodes, x);
    while (nodes[x].child[0] >= 0) { x = nodes[x].child[0]; push(nodes, x); }
    splay(nodes, x);
    return x;
}

static bool link_nodes(lct_node nodes[MAX_N], int u, int v) {
    if (u == v) return false;
    make_root(nodes, u);
    if (find_root(nodes, v) == u) return false;
    nodes[u].parent = v;
    return true;
}

static bool cut_nodes(lct_node nodes[MAX_N], int u, int v) {
    if (u == v) return false;
    make_root(nodes, u);
    access(nodes, v);
    if (nodes[v].child[0] != u || nodes[u].child[1] >= 0) return false;
    nodes[v].child[0] = -1;
    nodes[u].parent = -1;
    pull(nodes, v);
    return true;
}

static void set_value(lct_node nodes[MAX_N], int vertex, affine value) {
    access(nodes, vertex);
    nodes[vertex].value = value;
    pull(nodes, vertex);
}

static bool path_composition(lct_node nodes[MAX_N], int u, int v, affine *result) {
    make_root(nodes, u);
    if (find_root(nodes, v) != u) return false;
    make_root(nodes, u);
    access(nodes, v);
    *result = nodes[v].forward;
    return true;
}

static size_t find_dsu(size_t parent[MAX_N], size_t item) {
    while (parent[item] != item) { parent[item] = parent[parent[item]]; item = parent[item]; }
    return item;
}

static bool connected(const bool adjacency[MAX_N][MAX_N], size_t n, size_t start, size_t target) {
    bool seen[MAX_N] = {false};
    size_t stack[MAX_N], top = 0;
    seen[start] = true;
    stack[top++] = start;
    while (top > 0) {
        const size_t u = stack[--top];
        if (u == target) return true;
        for (size_t v = 0; v < n; ++v)
            if (adjacency[u][v] && !seen[v]) { seen[v] = true; stack[top++] = v; }
    }
    return false;
}

static void store_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = (uint8_t)(bits & 255u); bits >>= 8; }
}

int64_t dynamic_tree_vertex_set_path_composite(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length < 2 + 2 * n + 2 * (n - 1) + 4 * q) return -1;
    affine values[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        const int64_t multiplier = input[2 + 2 * i], addend = input[3 + 2 * i];
        if (multiplier < 1 || multiplier >= MODULUS || addend < 0 || addend >= MODULUS) return -1;
        values[i] = (affine){multiplier, addend};
    }
    bool adjacency[MAX_N][MAX_N] = {{false}};
    size_t dsu[MAX_N];
    for (size_t i = 0; i < n; ++i) dsu[i] = i;
    size_t edge_u[MAX_N] = {0}, edge_v[MAX_N] = {0};
    size_t cursor = 2 + 2 * n;
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const int64_t u_value = input[cursor++], v_value = input[cursor++];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) return -1;
        const size_t u = (size_t)u_value, v = (size_t)v_value;
        const size_t root_u = find_dsu(dsu, u), root_v = find_dsu(dsu, v);
        if (root_u == root_v) return -1;
        dsu[root_v] = root_u;
        adjacency[u][v] = adjacency[v][u] = true;
        edge_u[edge] = u; edge_v[edge] = v;
    }
    query queries[MAX_Q];
    size_t answer_count = 0;
    for (size_t i = 0; i < q; ++i) {
        if (cursor >= length) return -1;
        const int64_t kind = input[cursor++];
        query current = {kind, 0, 0, 0, 0};
        if (kind == 0) {
            if (length - cursor < 4) return -1;
            current.a = input[cursor++]; current.b = input[cursor++];
            current.c = input[cursor++]; current.d = input[cursor++];
            if (current.a < 0 || current.a >= n_value || current.b < 0 || current.b >= n_value ||
                current.c < 0 || current.c >= n_value || current.d < 0 || current.d >= n_value ||
                current.a == current.b || current.c == current.d) return -1;
            const size_t u = (size_t)current.a, v = (size_t)current.b;
            const size_t w = (size_t)current.c, x = (size_t)current.d;
            if (!adjacency[u][v]) return -1;
            adjacency[u][v] = adjacency[v][u] = false;
            if (connected(adjacency, n, w, x)) return -1;
            adjacency[w][x] = adjacency[x][w] = true;
        } else if (kind == 1) {
            if (length - cursor < 3) return -1;
            current.a = input[cursor++]; current.b = input[cursor++]; current.c = input[cursor++];
            if (current.a < 0 || current.a >= n_value || current.b < 1 || current.b >= MODULUS ||
                current.c < 0 || current.c >= MODULUS) return -1;
        } else if (kind == 2) {
            if (length - cursor < 3) return -1;
            current.a = input[cursor++]; current.b = input[cursor++]; current.c = input[cursor++];
            if (current.a < 0 || current.a >= n_value || current.b < 0 || current.b >= n_value ||
                current.c < 0 || current.c >= MODULUS) return -1;
            ++answer_count;
        } else return -1;
        queries[i] = current;
    }
    if (cursor != length) return -1;
    const size_t required = 8 * answer_count;
    if (output == NULL || capacity < required) return -2;

    lct_node nodes[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        nodes[i] = (lct_node){.child = {-1, -1}, .parent = -1, .reversed = false,
            .value = values[i], .forward = values[i], .backward = values[i]};
    }
    for (size_t edge = 0; edge + 1 < n; ++edge)
        if (!link_nodes(nodes, (int)edge_u[edge], (int)edge_v[edge])) return -1;
    int64_t answers[MAX_Q];
    size_t written = 0;
    for (size_t i = 0; i < q; ++i) {
        const query current = queries[i];
        if (current.kind == 0) {
            if (!cut_nodes(nodes, (int)current.a, (int)current.b) ||
                !link_nodes(nodes, (int)current.c, (int)current.d)) return -1;
        } else if (current.kind == 1) {
            set_value(nodes, (int)current.a, (affine){current.b, current.c});
        } else {
            affine combined;
            if (!path_composition(nodes, (int)current.a, (int)current.b, &combined)) return -1;
            answers[written++] = (combined.multiplier * current.c + combined.addend) % MODULUS;
        }
    }
    for (size_t i = 0; i < written; ++i) store_le(output, 8 * i, answers[i]);
    return (int64_t)required;
}
