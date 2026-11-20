#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_M = 96, MAX_D = 192, INF_LEVEL = 1000 };
typedef struct { int low, high; } Interval;
typedef struct { Interval left, right; } Conflict;
typedef struct {
    int n, m;
    int eu[MAX_M], ev[MAX_M], edge_of[MAX_N][MAX_N];
    int degree[MAX_N], adj[MAX_N][MAX_N];
    int tail[MAX_M], head[MAX_M], height[MAX_N], parent[MAX_N];
    int low[MAX_M], low2[MAX_M], nest[MAX_M];
    int out_count[MAX_N], out[MAX_N][MAX_N];
    int ref[MAX_M], side[MAX_M], low_edge[MAX_M], bottom[MAX_M];
    Conflict stack[MAX_D]; int stack_len;
    int rotation_count[MAX_N], rotation[MAX_N][MAX_N];
    int left_ref[MAX_N], right_ref[MAX_N];
    int roots[MAX_N], root_count;
} State;

static Interval empty_interval(void) { Interval x = {-1, -1}; return x; }
static int interval_empty(Interval x) { return x.low < 0; }
static Conflict empty_conflict(void) { Conflict p = {{-1,-1},{-1,-1}}; return p; }
static void swap_intervals(Conflict *p) { Interval t = p->left; p->left = p->right; p->right = t; }

static void update_parent_lowpoints(State *s, int back, int pe) {
    if (pe < 0) return;
    if (s->low[back] < s->low[pe]) {
        s->low2[pe] = s->low[pe] < s->low2[back] ? s->low[pe] : s->low2[back];
        s->low[pe] = s->low[back];
    } else if (s->low[back] > s->low[pe]) {
        if (s->low[back] < s->low2[pe]) s->low2[pe] = s->low[back];
    } else if (s->low2[back] < s->low2[pe]) s->low2[pe] = s->low2[back];
}

static void orient_dfs(State *s, int v) {
    const int pe = s->parent[v];
    for (int i = 0; i < s->degree[v]; ++i) {
        int w = s->adj[v][i], e = s->edge_of[v][w];
        if (s->tail[e] >= 0) continue;
        s->tail[e] = v; s->head[e] = w;
        s->low[e] = s->height[v]; s->low2[e] = s->height[v];
        if (s->height[w] < 0) {
            s->parent[w] = e; s->height[w] = s->height[v] + 1;
            orient_dfs(s, w);
            s->nest[e] = 2*s->low[e] + (s->low2[e] < s->height[v]);
        } else {
            s->low[e] = s->height[w]; s->low2[e] = s->height[v];
            s->nest[e] = 2*s->low[e] + (s->low2[e] < s->height[v]);
        }
        update_parent_lowpoints(s, e, pe);
    }
}

static int interval_conflicts(const State *s, Interval a, int e) {
    return a.high >= 0 && s->low[a.high] > s->low[e];
}
static int conflict_lowest(const State *s, Conflict p) {
    int a = p.left.low >= 0 ? s->low[p.left.low] : INF_LEVEL;
    int b = p.right.low >= 0 ? s->low[p.right.low] : INF_LEVEL;
    return a < b ? a : b;
}

static int add_constraints(State *s, int ei, int pe) {
    Conflict p = empty_conflict();
    for (;;) {
        if (s->stack_len == 0) return 0;
        Conflict q = s->stack[--s->stack_len];
        if (!interval_empty(q.left)) swap_intervals(&q);
        if (!interval_empty(q.left)) return 0;
        if (s->low[q.right.low] > s->low[pe]) {
            if (interval_empty(p.right)) p.right = q.right;
            else { s->ref[p.right.low] = q.right.high; p.right.low = q.right.low; }
        } else s->ref[q.right.low] = s->low_edge[pe];
        if (s->stack_len - 1 == s->bottom[ei]) break;
    }
    while (s->stack_len > 0 && (interval_conflicts(s, s->stack[s->stack_len-1].left, ei) ||
           interval_conflicts(s, s->stack[s->stack_len-1].right, ei))) {
        Conflict q = s->stack[--s->stack_len];
        if (interval_conflicts(s, q.right, ei)) swap_intervals(&q);
        if (interval_conflicts(s, q.right, ei)) return 0;
        if (p.right.low >= 0) s->ref[p.right.low] = q.right.high;
        if (q.right.low >= 0) p.right.low = q.right.low;
        if (interval_empty(p.left)) p.left = q.left;
        else { s->ref[p.left.low] = q.left.high; p.left.low = q.left.low; }
    }
    if (!interval_empty(p.left) || !interval_empty(p.right)) s->stack[s->stack_len++] = p;
    return 1;
}

static void remove_parent_returns(State *s, int e) {
    int u = s->tail[e];
    while (s->stack_len > 0 && conflict_lowest(s, s->stack[s->stack_len-1]) == s->height[u]) {
        Conflict p = s->stack[--s->stack_len];
        if (p.left.low >= 0) s->side[p.left.low] = -1;
    }
    if (s->stack_len > 0) {
        Conflict p = s->stack[--s->stack_len];
        while (p.left.high >= 0 && s->head[p.left.high] == u) p.left.high = s->ref[p.left.high];
        if (p.left.high < 0 && p.left.low >= 0) {
            s->ref[p.left.low] = p.right.low; s->side[p.left.low] = -1; p.left.low = -1;
        }
        while (p.right.high >= 0 && s->head[p.right.high] == u) p.right.high = s->ref[p.right.high];
        if (p.right.high < 0 && p.right.low >= 0) {
            s->ref[p.right.low] = p.left.low; s->side[p.right.low] = -1; p.right.low = -1;
        }
        s->stack[s->stack_len++] = p;
    }
    if (s->low[e] < s->height[u] && s->stack_len > 0) {
        Conflict p = s->stack[s->stack_len-1];
        int lh = p.left.high, rh = p.right.high;
        s->ref[e] = lh >= 0 && (rh < 0 || s->low[lh] > s->low[rh]) ? lh : rh;
    }
}

static int test_dfs(State *s, int v) {
    int pe = s->parent[v];
    for (int i = 0; i < s->out_count[v]; ++i) {
        int e = s->out[v][i], w = s->head[e];
        s->bottom[e] = s->stack_len - 1;
        if (s->parent[w] == e) {
            if (!test_dfs(s, w)) return 0;
        } else {
            s->low_edge[e] = e;
            Conflict p = empty_conflict(); p.right.low = e; p.right.high = e;
            s->stack[s->stack_len++] = p;
            if (s->low[e] < s->height[v]) {
                if (i == 0) { if (pe >= 0) s->low_edge[pe] = s->low_edge[e]; }
                else if (pe < 0 || !add_constraints(s, e, pe)) return 0;
            }
        }
    }
    if (pe >= 0) remove_parent_returns(s, pe);
    return 1;
}

static int resolve_side(State *s, int e) {
    if (s->ref[e] >= 0) {
        int r = s->ref[e]; s->side[e] *= resolve_side(s, r); s->ref[e] = -1;
    }
    return s->side[e];
}
static int edge_before(const State *s, int a, int b, const int *depth) {
    return depth[a] < depth[b] || (depth[a] == depth[b] && s->head[a] < s->head[b]);
}
static void insert_rotation(State *s, int v, int w, int at, int after) {
    int count = s->rotation_count[v], pos = 0;
    if (count > 0 && at >= 0) {
        while (pos < count && s->rotation[v][pos] != at) ++pos;
        if (pos == count) pos = count;
        else if (after) pos = (pos + 1) % count;
    }
    for (int i = count; i > pos; --i) s->rotation[v][i] = s->rotation[v][i-1];
    s->rotation[v][pos] = w; s->rotation_count[v] = count + 1;
}
static void embed_dfs(State *s, int v) {
    for (int i = 0; i < s->out_count[v]; ++i) {
        int e = s->out[v][i], w = s->head[e];
        if (s->parent[w] == e) {
            insert_rotation(s, w, v, -1, 0);
            s->left_ref[v] = s->right_ref[v] = w;
            embed_dfs(s, w);
        } else if (s->side[e] == 1) {
            insert_rotation(s, w, v, s->right_ref[w], 1);
        } else {
            insert_rotation(s, w, v, s->left_ref[w], 0); s->left_ref[w] = v;
        }
    }
}

int64_t planar_embedding_lr(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 195) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || length != 2 + 2*(size_t)m64) return -1;
    State s = {0}; s.n = (int)n64; s.m = (int)m64;
    for (int u = 0; u < s.n; ++u) for (int v = 0; v < s.n; ++v) s.edge_of[u][v] = -1;
    for (int v = 0; v < s.n; ++v) { s.height[v] = -1; s.parent[v] = -1; s.left_ref[v] = s.right_ref[v] = -1; }
    for (int e = 0; e < s.m; ++e) {
        s.tail[e] = s.head[e] = s.ref[e] = s.low_edge[e] = s.bottom[e] = -1;
        s.side[e] = 1;
        int64_t u64 = input[2 + 2*(size_t)e], v64 = input[3 + 2*(size_t)e];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        int u = (int)u64, v = (int)v64;
        if (s.edge_of[u][v] >= 0) return -1;
        s.eu[e] = u; s.ev[e] = v; s.edge_of[u][v] = s.edge_of[v][u] = e;
    }
    for (int v = 0; v < s.n; ++v) for (int w = 0; w < s.n; ++w)
        if (s.edge_of[v][w] >= 0) s.adj[v][s.degree[v]++] = w;
    for (int root = 0; root < s.n; ++root) if (s.height[root] < 0) {
        s.height[root] = 0; s.roots[s.root_count++] = root; orient_dfs(&s, root);
    }
    for (int e = 0; e < s.m; ++e) s.out[s.tail[e]][s.out_count[s.tail[e]]++] = e;
    for (int v = 0; v < s.n; ++v) for (int i = 1; i < s.out_count[v]; ++i) {
        int e = s.out[v][i], j = i;
        while (j > 0 && edge_before(&s, e, s.out[v][j-1], s.nest)) { s.out[v][j] = s.out[v][j-1]; --j; }
        s.out[v][j] = e;
    }
    int planar = 1;
    for (int i = 0; i < s.root_count; ++i) if (!test_dfs(&s, s.roots[i])) { planar = 0; break; }
    if (!output) return -2;
    if (!planar) { if (capacity < 1) return -2; output[0] = 0; return 1; }
    int depth[MAX_M];
    for (int e = 0; e < s.m; ++e) depth[e] = s.nest[e] * resolve_side(&s, e);
    for (int v = 0; v < s.n; ++v) for (int i = 1; i < s.out_count[v]; ++i) {
        int e = s.out[v][i], j = i;
        while (j > 0 && edge_before(&s, e, s.out[v][j-1], depth)) { s.out[v][j] = s.out[v][j-1]; --j; }
        s.out[v][j] = e;
    }
    for (int v = 0; v < s.n; ++v) for (int i = 0; i < s.out_count[v]; ++i)
        s.rotation[v][s.rotation_count[v]++] = s.head[s.out[v][i]];
    for (int i = 0; i < s.root_count; ++i) embed_dfs(&s, s.roots[i]);
    size_t needed = 1 + 2*(size_t)s.m;
    if (capacity < needed) return -2;
    output[0] = 1; size_t at = 1;
    for (int v = 0; v < s.n; ++v) for (int i = 0; i < s.rotation_count[v]; ++i)
        output[at++] = (uint8_t)s.rotation[v][i];
    return (int64_t)needed;
}
