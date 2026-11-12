module euler_tour_tree;

const usz N = 8, M = 32, NODES = N + 2*M, INPUT_MAX = 2 + N + 3*M;
struct Op { long kind; long a; long b; }
struct Tree {
    int[NODES] left; int[NODES] right; int[NODES] parent; int[NODES] vertex; int[NODES] size; int[NODES] count;
    long[NODES] value; long[NODES] sum; ulong[NODES] priority;
    int[M] edge_u; int[M] edge_v; int[M] arc_uv; int[M] arc_vu; bool[M] active;
    usz next_node; usz edge_count;
}

fn ulong ett_mix(ulong x) {
    x += 0x9e3779b97f4a7c15u64; x = (x ^ (x >> 30))*0xbf58476d1ce4e5b9u64;
    x = (x ^ (x >> 27))*0x94d049bb133111ebu64; return x ^ (x >> 31);
}
fn int ett_size(Tree* t, int x) { return x < 0 ? 0 : t.size[x]; }
fn int ett_count(Tree* t, int x) { return x < 0 ? 0 : t.count[x]; }
fn long ett_sum(Tree* t, int x) { return x < 0 ? 0 : t.sum[x]; }
fn void ett_pull(Tree* t, int x) {
    if (x < 0) return;
    t.size[x] = 1 + ett_size(t,t.left[x]) + ett_size(t,t.right[x]);
    t.count[x] = (t.vertex[x] >= 0 ? 1 : 0) + ett_count(t,t.left[x]) + ett_count(t,t.right[x]);
    t.sum[x] = t.value[x] + ett_sum(t,t.left[x]) + ett_sum(t,t.right[x]);
}
fn int ett_merge(Tree* t, int a, int b) {
    if (a < 0) { if (b >= 0) t.parent[b] = -1; return b; }
    if (b < 0) { t.parent[a] = -1; return a; }
    if (t.priority[a] > t.priority[b]) {
        t.right[a] = ett_merge(t,t.right[a],b); if (t.right[a] >= 0) t.parent[t.right[a]] = a;
        ett_pull(t,a); t.parent[a] = -1; return a;
    }
    t.left[b] = ett_merge(t,a,t.left[b]); if (t.left[b] >= 0) t.parent[t.left[b]] = b;
    ett_pull(t,b); t.parent[b] = -1; return b;
}
fn void ett_split(Tree* t, int root, int prefix, int* first, int* rest) {
    if (root < 0) { *first = -1; *rest = -1; return; }
    if (prefix <= ett_size(t,t.left[root])) {
        ett_split(t,t.left[root],prefix,first,rest); t.left[root] = *rest;
        if (*rest >= 0) t.parent[*rest] = root; ett_pull(t,root); t.parent[root] = -1;
        if (*first >= 0) t.parent[*first] = -1; *rest = root; return;
    }
    ett_split(t,t.right[root],prefix-ett_size(t,t.left[root])-1,first,rest); t.right[root] = *first;
    if (*first >= 0) t.parent[*first] = root; ett_pull(t,root); t.parent[root] = -1;
    if (*rest >= 0) t.parent[*rest] = -1; *first = root;
}
fn int ett_root(Tree* t, int x) { while (t.parent[x] >= 0) x = t.parent[x]; return x; }
fn int ett_position(Tree* t, int x) {
    int result = ett_size(t,t.left[x]);
    while (t.parent[x] >= 0) { int p = t.parent[x]; if (t.right[p] == x) result += 1 + ett_size(t,t.left[p]); x = p; }
    return result;
}
fn int ett_rotate(Tree* t, int root, int x) { int first, rest; ett_split(t,root,ett_position(t,x),&first,&rest); return ett_merge(t,rest,first); }
fn bool ett_connected(bool[N*N]* adj, int start, int target, int n) {
    bool[N] seen = zeroed; int[N] stack = zeroed; int top = 0; stack[top++] = start; seen[start] = true;
    while (top > 0) { int u = stack[--top]; if (u == target) return true;
        for (int v = 0; v < n; v++) if (adj[u*N+v] && !seen[v]) { seen[v] = true; stack[top++] = v; }
    }
    return false;
}
fn void ett_initialize(Tree* t, long[N]* weight, int n) {
    for (int i = 0; i < (int)NODES; i++) {
        t.left[i] = -1; t.right[i] = -1; t.parent[i] = -1; t.vertex[i] = -1;
        t.size[i] = 0; t.count[i] = 0; t.value[i] = 0; t.sum[i] = 0; t.priority[i] = ett_mix((ulong)i);
    }
    for (int i = 0; i < n; i++) { t.vertex[i] = i; t.value[i] = weight[i]; t.size[i] = 1; t.count[i] = 1; t.sum[i] = weight[i]; }
    t.next_node = (usz)n; t.edge_count = 0;
}
fn void ett_link(Tree* t, int u, int v) {
    int a = ett_rotate(t,ett_root(t,u),u), b = ett_rotate(t,ett_root(t,v),v);
    int uv = (int)t.next_node++, vu = (int)t.next_node++;
    int[2] arcs = {uv,vu};
    for (int i = 0; i < 2; i++) { int x = arcs[i]; t.left[x] = -1; t.right[x] = -1; t.parent[x] = -1; t.vertex[x] = -1; t.value[x] = 0; t.size[x] = 1; t.count[x] = 0; t.sum[x] = 0; }
    int root = ett_merge(t,ett_merge(t,ett_merge(t,a,uv),b),vu); t.parent[root] = -1;
    usz e = t.edge_count++; t.edge_u[e] = u; t.edge_v[e] = v; t.arc_uv[e] = uv; t.arc_vu[e] = vu; t.active[e] = true;
}
fn bool ett_cut(Tree* t, int u, int v) {
    int edge = -1;
    int i = (int)t.edge_count-1;
    while (i >= 0) { if (t.active[i] && ((t.edge_u[i] == u && t.edge_v[i] == v) || (t.edge_u[i] == v && t.edge_v[i] == u))) { edge = i; break; } i--; }
    if (edge < 0) return false;
    int first_arc = t.arc_vu[edge]; if (t.edge_u[edge] == u && t.edge_v[edge] == v) first_arc = t.arc_uv[edge];
    int second_arc = first_arc == t.arc_uv[edge] ? t.arc_vu[edge] : t.arc_uv[edge];
    int root = ett_rotate(t,ett_root(t,first_arc),first_arc), drop, rest; ett_split(t,root,1,&drop,&rest);
    int between, suffix; ett_split(t,rest,ett_position(t,second_arc),&between,&suffix);
    int drop_second, other; ett_split(t,suffix,1,&drop_second,&other);
    if (between >= 0) t.parent[between] = -1; if (other >= 0) t.parent[other] = -1;
    t.active[edge] = false; return true;
}
fn void ett_set_weight(Tree* t, int vertex, long value) {
    t.value[vertex] = value; int[NODES] path = zeroed; int count = 0;
    int x = vertex; while (x >= 0) { path[count++] = x; x = t.parent[x]; }
    for (int i = 0; i < count; i++) ett_pull(t,path[i]);
}
fn void ett_store(uint8* output, usz at, long value) {
    ulong bits = (ulong)value; for (usz i = 0; i < 8; i++) output[at+i] = (uint8)((bits >> (8*i)) & 255);
}

fn long euler_tour_tree(long* input, usz length, uint8* output, usz capacity) @export("euler_tour_tree") {
    if (input == null || length < 2 || length > INPUT_MAX) return -1;
    long nr = input[0], mr = input[1]; if (nr < 1 || nr > (long)N || mr < 1 || mr > (long)M) return -1;
    int n = (int)nr, m = (int)mr; usz cursor = 2; long[N] weights = zeroed;
    for (int i = 0; i < n; i++) { if (cursor >= length) return -1; weights[i] = input[cursor++]; if (weights[i] < -100 || weights[i] > 100) return -1; }
    Op[M] ops = zeroed; int query_count = 0;
    for (int i = 0; i < m; i++) {
        if (cursor >= length) return -1; long kind = input[cursor++];
        if (kind == 0 || kind == 1) { if (cursor+2 > length) return -1; long u = input[cursor++], v = input[cursor++]; if (u < 0 || u >= n || v < 0 || v >= n || u == v) return -1; ops[i] = {kind,u,v}; }
        else if (kind == 2) { if (cursor+2 > length) return -1; long v = input[cursor++], w = input[cursor++]; if (v < 0 || v >= n || w < -100 || w > 100) return -1; ops[i] = {kind,v,w}; }
        else if (kind == 3) { if (cursor >= length) return -1; long v = input[cursor++]; if (v < 0 || v >= n) return -1; ops[i] = {kind,v,0}; query_count++; }
        else return -1;
    }
    if (cursor != length || query_count == 0) return -1;
    bool[N*N] adjacency = zeroed;
    for (int i = 0; i < m; i++) { Op op = ops[i]; int u = (int)op.a, v = (int)op.b;
        if (op.kind == 0) { if (ett_connected(&adjacency,u,v,n)) return -1; adjacency[u*N+v] = true; adjacency[v*N+u] = true; }
        else if (op.kind == 1) { if (!adjacency[u*N+v]) return -1; adjacency[u*N+v] = false; adjacency[v*N+u] = false; }
    }
    usz required = 16*(usz)query_count; if (output == null || capacity < required) return -2;
    Tree tree = zeroed; ett_initialize(&tree,&weights,n); long[2*M] answers = zeroed; usz answer_count = 0;
    for (int i = 0; i < m; i++) { Op op = ops[i]; int a = (int)op.a, b = (int)op.b;
        if (op.kind == 0) ett_link(&tree,a,b); else if (op.kind == 1) ett_cut(&tree,a,b); else if (op.kind == 2) ett_set_weight(&tree,a,op.b);
        else { int root = ett_root(&tree,a); answers[answer_count++] = tree.count[root]; answers[answer_count++] = tree.sum[root]; }
    }
    for (usz i = 0; i < answer_count; i++) ett_store(output,8*i,answers[i]); return (long)required;
}
