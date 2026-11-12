#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { ETT_N = 8, ETT_M = 32, ETT_NODES = ETT_N + 2 * ETT_M, ETT_INPUT_MAX = 2 + ETT_N + 3 * ETT_M };
typedef struct { int64_t kind, a, b; } EttOp;
typedef struct {
    int left[ETT_NODES], right[ETT_NODES], parent[ETT_NODES], vertex[ETT_NODES], size[ETT_NODES], count[ETT_NODES];
    int64_t value[ETT_NODES], sum[ETT_NODES];
    uint64_t priority[ETT_NODES];
    int edge_u[ETT_M], edge_v[ETT_M], arc_uv[ETT_M], arc_vu[ETT_M];
    bool active[ETT_M];
    size_t next_node, edge_count;
} EttTree;

static uint64_t ett_mix(uint64_t x) {
    x += UINT64_C(0x9e3779b97f4a7c15); x = (x ^ (x >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
    x = (x ^ (x >> 27)) * UINT64_C(0x94d049bb133111eb); return x ^ (x >> 31);
}
static int ett_size(const EttTree *t, int x) { return x < 0 ? 0 : t->size[x]; }
static int ett_count(const EttTree *t, int x) { return x < 0 ? 0 : t->count[x]; }
static int64_t ett_sum(const EttTree *t, int x) { return x < 0 ? 0 : t->sum[x]; }
static void ett_pull(EttTree *t, int x) {
    if (x < 0) return;
    t->size[x] = 1 + ett_size(t, t->left[x]) + ett_size(t, t->right[x]);
    t->count[x] = (t->vertex[x] >= 0) + ett_count(t, t->left[x]) + ett_count(t, t->right[x]);
    t->sum[x] = t->value[x] + ett_sum(t, t->left[x]) + ett_sum(t, t->right[x]);
}
static int ett_merge(EttTree *t, int a, int b) {
    if (a < 0) { if (b >= 0) t->parent[b] = -1; return b; }
    if (b < 0) { t->parent[a] = -1; return a; }
    if (t->priority[a] > t->priority[b]) {
        t->right[a] = ett_merge(t, t->right[a], b); if (t->right[a] >= 0) t->parent[t->right[a]] = a;
        ett_pull(t, a); t->parent[a] = -1; return a;
    }
    t->left[b] = ett_merge(t, a, t->left[b]); if (t->left[b] >= 0) t->parent[t->left[b]] = b;
    ett_pull(t, b); t->parent[b] = -1; return b;
}
static void ett_split(EttTree *t, int root, int prefix, int *first, int *rest) {
    if (root < 0) { *first = *rest = -1; return; }
    if (prefix <= ett_size(t, t->left[root])) {
        ett_split(t, t->left[root], prefix, first, rest); t->left[root] = *rest;
        if (*rest >= 0) t->parent[*rest] = root; ett_pull(t, root); t->parent[root] = -1;
        if (*first >= 0) t->parent[*first] = -1; *rest = root; return;
    }
    ett_split(t, t->right[root], prefix - ett_size(t, t->left[root]) - 1, first, rest); t->right[root] = *first;
    if (*first >= 0) t->parent[*first] = root; ett_pull(t, root); t->parent[root] = -1;
    if (*rest >= 0) t->parent[*rest] = -1; *first = root;
}
static int ett_root(const EttTree *t, int x) { while (t->parent[x] >= 0) x = t->parent[x]; return x; }
static int ett_position(const EttTree *t, int x) {
    int result = ett_size(t, t->left[x]);
    while (t->parent[x] >= 0) { int p = t->parent[x]; if (t->right[p] == x) result += 1 + ett_size(t, t->left[p]); x = p; }
    return result;
}
static int ett_rotate(EttTree *t, int root, int x) { int first, rest; ett_split(t, root, ett_position(t, x), &first, &rest); return ett_merge(t, rest, first); }
static bool ett_connected(const bool adj[ETT_N][ETT_N], int start, int target, int n) {
    bool seen[ETT_N] = {false}; int stack[ETT_N], top = 0; stack[top++] = start; seen[start] = true;
    while (top) { int u = stack[--top]; if (u == target) return true;
        for (int v = 0; v < n; ++v) if (adj[u][v] && !seen[v]) { seen[v] = true; stack[top++] = v; }
    }
    return false;
}
static void ett_initialize(EttTree *t, const int64_t weight[ETT_N], int n) {
    for (int i = 0; i < ETT_NODES; ++i) { t->left[i] = t->right[i] = t->parent[i] = -1; t->vertex[i] = -1; t->size[i] = t->count[i] = 0; t->value[i] = t->sum[i] = 0; t->priority[i] = ett_mix((uint64_t)i); }
    for (int i = 0; i < n; ++i) { t->vertex[i] = i; t->value[i] = t->sum[i] = weight[i]; t->size[i] = t->count[i] = 1; }
    t->next_node = (size_t)n; t->edge_count = 0;
}
static void ett_link(EttTree *t, int u, int v) {
    int a = ett_rotate(t, ett_root(t, u), u), b = ett_rotate(t, ett_root(t, v), v);
    int uv = (int)t->next_node++, vu = (int)t->next_node++;
    int arcs[2] = {uv, vu};
    for (int i = 0; i < 2; ++i) { int x = arcs[i]; t->left[x] = t->right[x] = t->parent[x] = -1; t->vertex[x] = -1; t->value[x] = t->sum[x] = 0; t->size[x] = 1; t->count[x] = 0; }
    int root = ett_merge(t, ett_merge(t, ett_merge(t, a, uv), b), vu); t->parent[root] = -1;
    size_t e = t->edge_count++; t->edge_u[e] = u; t->edge_v[e] = v; t->arc_uv[e] = uv; t->arc_vu[e] = vu; t->active[e] = true;
}
static bool ett_cut(EttTree *t, int u, int v) {
    int edge = -1;
    for (int i = (int)t->edge_count - 1; i >= 0; --i) if (t->active[i] && ((t->edge_u[i] == u && t->edge_v[i] == v) || (t->edge_u[i] == v && t->edge_v[i] == u))) { edge = i; break; }
    if (edge < 0) return false;
    int first_arc = (t->edge_u[edge] == u && t->edge_v[edge] == v) ? t->arc_uv[edge] : t->arc_vu[edge];
    int second_arc = first_arc == t->arc_uv[edge] ? t->arc_vu[edge] : t->arc_uv[edge];
    int root = ett_rotate(t, ett_root(t, first_arc), first_arc), drop, rest; ett_split(t, root, 1, &drop, &rest);
    int between, suffix; ett_split(t, rest, ett_position(t, second_arc), &between, &suffix);
    int drop_second, other; ett_split(t, suffix, 1, &drop_second, &other);
    if (between >= 0) t->parent[between] = -1; if (other >= 0) t->parent[other] = -1;
    t->active[edge] = false; return true;
}
static void ett_set_weight(EttTree *t, int vertex, int64_t value) {
    t->value[vertex] = value; int path[ETT_NODES], count = 0;
    for (int x = vertex; x >= 0; x = t->parent[x]) path[count++] = x;
    for (int i = 0; i < count; ++i) ett_pull(t, path[i]);
}
static void ett_store(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value; for (size_t b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8 * b));
}

int64_t euler_tour_tree(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > ETT_INPUT_MAX) return -1;
    int64_t nr = input[0], mr = input[1]; if (nr < 1 || nr > ETT_N || mr < 1 || mr > ETT_M) return -1;
    int n = (int)nr, m = (int)mr; size_t cursor = 2; int64_t weights[ETT_N] = {0};
    for (int i = 0; i < n; ++i) { if (cursor >= length) return -1; weights[i] = input[cursor++]; if (weights[i] < -100 || weights[i] > 100) return -1; }
    EttOp ops[ETT_M] = {{0}}; int query_count = 0;
    for (int i = 0; i < m; ++i) {
        if (cursor >= length) return -1; int64_t kind = input[cursor++];
        if (kind == 0 || kind == 1) { if (cursor + 2 > length) return -1; int64_t u = input[cursor++], v = input[cursor++]; if (u < 0 || u >= n || v < 0 || v >= n || u == v) return -1; ops[i] = (EttOp){kind,u,v}; }
        else if (kind == 2) { if (cursor + 2 > length) return -1; int64_t v = input[cursor++], w = input[cursor++]; if (v < 0 || v >= n || w < -100 || w > 100) return -1; ops[i] = (EttOp){kind,v,w}; }
        else if (kind == 3) { if (cursor >= length) return -1; int64_t v = input[cursor++]; if (v < 0 || v >= n) return -1; ops[i] = (EttOp){kind,v,0}; ++query_count; }
        else return -1;
    }
    if (cursor != length || query_count == 0) return -1;
    bool adjacency[ETT_N][ETT_N] = {{false}};
    for (int i = 0; i < m; ++i) { EttOp op = ops[i]; int u = (int)op.a, v = (int)op.b;
        if (op.kind == 0) { if (ett_connected(adjacency,u,v,n)) return -1; adjacency[u][v] = adjacency[v][u] = true; }
        else if (op.kind == 1) { if (!adjacency[u][v]) return -1; adjacency[u][v] = adjacency[v][u] = false; }
    }
    size_t required = (size_t)16 * (size_t)query_count; if (!output || capacity < required) return -2;
    EttTree tree; ett_initialize(&tree, weights, n); int64_t answers[2 * ETT_M] = {0}; size_t count = 0;
    for (int i = 0; i < m; ++i) { EttOp op = ops[i]; int a = (int)op.a, b = (int)op.b;
        if (op.kind == 0) ett_link(&tree,a,b); else if (op.kind == 1) (void)ett_cut(&tree,a,b); else if (op.kind == 2) ett_set_weight(&tree,a,op.b);
        else { int root = ett_root(&tree,a); answers[count++] = tree.count[root]; answers[count++] = tree.sum[root]; }
    }
    for (size_t i = 0; i < count; ++i) ett_store(output,8*i,answers[i]); return (int64_t)required;
}
