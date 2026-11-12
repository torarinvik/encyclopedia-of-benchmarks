module dynamic_tree_vertex_set_path_composite;

const long MODULUS = 998244353;
const usz MAX_N = 8;
const usz MAX_Q = 12;
const usz MAX_INPUT = 93;

struct Affine { long multiplier; long addend; }
struct LctNode {
    int child0; int child1; int parent; bool reversed;
    Affine value; Affine forward; Affine backward;
}
struct Query { long kind; long a; long b; long c; long d; }

fn Affine identity() { return {1, 0}; }
fn Affine compose(Affine after, Affine before) {
    return {after.multiplier * before.multiplier % MODULUS,
        (after.multiplier * before.addend + after.addend) % MODULUS};
}
fn bool is_aux_root(LctNode* nodes, int x) {
    int p = nodes[x].parent;
    return p < 0 || (nodes[p].child0 != x && nodes[p].child1 != x);
}
fn void pull(LctNode* nodes, int x) {
    Affine lf = nodes[x].child0 < 0 ? identity() : nodes[nodes[x].child0].forward;
    Affine rf = nodes[x].child1 < 0 ? identity() : nodes[nodes[x].child1].forward;
    Affine lb = nodes[x].child0 < 0 ? identity() : nodes[nodes[x].child0].backward;
    Affine rb = nodes[x].child1 < 0 ? identity() : nodes[nodes[x].child1].backward;
    nodes[x].forward = compose(rf, compose(nodes[x].value, lf));
    nodes[x].backward = compose(lb, compose(nodes[x].value, rb));
}
fn void reverse_path(LctNode* nodes, int x) {
    if (x < 0) return;
    int temporary = nodes[x].child0; nodes[x].child0 = nodes[x].child1; nodes[x].child1 = temporary;
    Affine aggregate = nodes[x].forward; nodes[x].forward = nodes[x].backward; nodes[x].backward = aggregate;
    nodes[x].reversed = !nodes[x].reversed;
}
fn void push(LctNode* nodes, int x) {
    if (!nodes[x].reversed) return;
    reverse_path(nodes, nodes[x].child0); reverse_path(nodes, nodes[x].child1);
    nodes[x].reversed = false;
}
fn void rotate(LctNode* nodes, int x) {
    int p = nodes[x].parent, g = nodes[p].parent;
    bool right_child = nodes[p].child1 == x;
    int middle = right_child ? nodes[x].child0 : nodes[x].child1;
    if (!is_aux_root(nodes, p)) {
        if (nodes[g].child0 == p) nodes[g].child0 = x; else nodes[g].child1 = x;
    }
    nodes[x].parent = g;
    if (right_child) { nodes[x].child0 = p; nodes[p].child1 = middle; }
    else { nodes[x].child1 = p; nodes[p].child0 = middle; }
    nodes[p].parent = x;
    if (middle >= 0) nodes[middle].parent = p;
    pull(nodes, p); pull(nodes, x);
}
fn void splay(LctNode* nodes, int x) {
    int[MAX_N] stack; int count = 0, y = x;
    stack[count++] = y;
    while (!is_aux_root(nodes, y)) { y = nodes[y].parent; stack[count++] = y; }
    while (count > 0) push(nodes, stack[--count]);
    while (!is_aux_root(nodes, x)) {
        int p = nodes[x].parent;
        if (!is_aux_root(nodes, p)) {
            int g = nodes[p].parent;
            bool zigzig = (nodes[p].child0 == x) == (nodes[g].child0 == p);
            rotate(nodes, zigzig ? p : x);
        }
        rotate(nodes, x);
    }
}
fn void access(LctNode* nodes, int x) {
    int last = -1;
    for (int y = x; y >= 0;) {
        splay(nodes, y); nodes[y].child1 = last;
        if (last >= 0) nodes[last].parent = y;
        pull(nodes, y); last = y; y = nodes[y].parent;
    }
    splay(nodes, x);
}
fn void make_root(LctNode* nodes, int x) { access(nodes, x); reverse_path(nodes, x); }
fn int find_root(LctNode* nodes, int x) {
    access(nodes, x); push(nodes, x);
    while (nodes[x].child0 >= 0) { x = nodes[x].child0; push(nodes, x); }
    splay(nodes, x); return x;
}
fn bool link_nodes(LctNode* nodes, int u, int v) {
    if (u == v) return false;
    make_root(nodes, u); if (find_root(nodes, v) == u) return false;
    nodes[u].parent = v; return true;
}
fn bool cut_nodes(LctNode* nodes, int u, int v) {
    if (u == v) return false;
    make_root(nodes, u); access(nodes, v);
    if (nodes[v].child0 != u || nodes[u].child1 >= 0) return false;
    nodes[v].child0 = -1; nodes[u].parent = -1; pull(nodes, v); return true;
}
fn void set_value(LctNode* nodes, int vertex, Affine value) {
    access(nodes, vertex); nodes[vertex].value = value; pull(nodes, vertex);
}
fn bool path_composition(LctNode* nodes, int u, int v, Affine* result) {
    make_root(nodes, u); if (find_root(nodes, v) != u) return false;
    make_root(nodes, u); access(nodes, v); *result = nodes[v].forward; return true;
}
fn usz find_dsu(usz* parent, usz item) {
    while (parent[item] != item) { parent[item] = parent[parent[item]]; item = parent[item]; }
    return item;
}
fn bool connected(bool* adjacency, usz n, usz start, usz target) {
    bool[MAX_N] seen = {false}; usz[MAX_N] stack = {0}; usz top = 0;
    seen[start] = true; stack[top++] = start;
    while (top > 0) {
        usz u = stack[--top]; if (u == target) return true;
        for (usz v = 0; v < n; v++) {
            if (adjacency[u * MAX_N + v] && !seen[v]) { seen[v] = true; stack[top++] = v; }
        }
    }
    return false;
}
fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits & 255ul); bits >>= 8; }
}

fn long dynamic_tree_vertex_set_path_composite(long* input, usz length,
    uint8* output, usz capacity) @export("dynamic_tree_vertex_set_path_composite") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 1 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length < 2 + 2 * n + 2 * (n - 1) + 4 * q) return -1;
    Affine[MAX_N] values = {0};
    for (usz i = 0; i < n; i++) {
        long m = input[2 + 2 * i], b = input[3 + 2 * i];
        if (m < 1 || m >= MODULUS || b < 0 || b >= MODULUS) return -1;
        values[i] = {m, b};
    }
    bool[MAX_N * MAX_N] adjacency = {false};
    usz[MAX_N] dsu = {0};
    for (usz i = 0; i < n; i++) dsu[i] = i;
    usz[MAX_N] edge_u = {0}, edge_v = {0};
    usz cursor = 2 + 2 * n;
    for (usz edge = 0; edge + 1 < n; edge++) {
        long uv = input[cursor++], vv = input[cursor++];
        if (uv < 0 || uv >= n_value || vv < 0 || vv >= n_value || uv == vv) return -1;
        usz u = (usz)uv, v = (usz)vv, ru = find_dsu(&dsu[0], u), rv = find_dsu(&dsu[0], v);
        if (ru == rv) return -1;
        dsu[rv] = ru; adjacency[u * MAX_N + v] = true; adjacency[v * MAX_N + u] = true;
        edge_u[edge] = u; edge_v[edge] = v;
    }
    Query[MAX_Q] queries = {0}; usz answer_count = 0;
    for (usz i = 0; i < q; i++) {
        if (cursor >= length) return -1;
        Query current = {input[cursor++], 0, 0, 0, 0};
        if (current.kind == 0) {
            if (length - cursor < 4) return -1;
            current.a=input[cursor++]; current.b=input[cursor++]; current.c=input[cursor++]; current.d=input[cursor++];
            if (current.a<0 || current.a>=n_value || current.b<0 || current.b>=n_value || current.c<0 || current.c>=n_value || current.d<0 || current.d>=n_value || current.a==current.b || current.c==current.d) return -1;
            usz u=(usz)current.a,v=(usz)current.b,w=(usz)current.c,x=(usz)current.d;
            if (!adjacency[u*MAX_N+v]) return -1;
            adjacency[u*MAX_N+v]=false; adjacency[v*MAX_N+u]=false;
            if (connected(&adjacency[0], n, w, x)) return -1;
            adjacency[w*MAX_N+x]=true; adjacency[x*MAX_N+w]=true;
        } else if (current.kind == 1) {
            if (length - cursor < 3) return -1;
            current.a=input[cursor++]; current.b=input[cursor++]; current.c=input[cursor++];
            if (current.a<0 || current.a>=n_value || current.b<1 || current.b>=MODULUS || current.c<0 || current.c>=MODULUS) return -1;
        } else if (current.kind == 2) {
            if (length - cursor < 3) return -1;
            current.a=input[cursor++]; current.b=input[cursor++]; current.c=input[cursor++];
            if (current.a<0 || current.a>=n_value || current.b<0 || current.b>=n_value || current.c<0 || current.c>=MODULUS) return -1;
            answer_count++;
        } else return -1;
        queries[i] = current;
    }
    if (cursor != length) return -1;
    usz required = 8 * answer_count;
    if (output == null || capacity < required) return -2;
    LctNode[MAX_N] nodes;
    for (usz i=0;i<n;i++) nodes[i]={.child0=-1,.child1=-1,.parent=-1,.reversed=false,.value=values[i],.forward=values[i],.backward=values[i]};
    for (usz e=0;e+1<n;e++) if (!link_nodes(&nodes[0], (int)edge_u[e], (int)edge_v[e])) return -1;
    long[MAX_Q] answers={0}; usz written=0;
    for (usz i=0;i<q;i++) {
        Query z=queries[i];
        if (z.kind==0) { if (!cut_nodes(&nodes[0],(int)z.a,(int)z.b) || !link_nodes(&nodes[0],(int)z.c,(int)z.d)) return -1; }
        else if (z.kind==1) set_value(&nodes[0],(int)z.a,{z.b,z.c});
        else { Affine combined; if (!path_composition(&nodes[0],(int)z.a,(int)z.b,&combined)) return -1; answers[written++]=(combined.multiplier*z.c+combined.addend)%MODULUS; }
    }
    for (usz i=0;i<written;i++) store_le(output,8*i,answers[i]);
    return (long)required;
}
