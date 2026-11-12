module dynamic_tree_subtree_add_subtree_sum;

const usz MAX_N = 16;
const usz MAX_Q = 32;
const usz MAX_TOKENS = MAX_N + 2 * (MAX_N - 1 + MAX_Q);
const usz MAX_INPUT = 3 * MAX_N + 5 * MAX_Q + 1;
const long MAX_DELTA = 1000;

struct Tour_Node {
    int left; int right; int parent;
    uint priority;
    usz sequence_size; usz marker_count;
    bool marker;
    long own_value; long sum; long lazy_add;
}
struct Tour {
    Tour_Node[MAX_TOKENS] nodes;
    usz next_node;
    uint random_state;
}
struct Split { int first; int second; }
struct Edge_Tokens { int forward; int reverse; }

fn usz seq_size(Tour* tour, int id) {
    if (id < 0) return 0;
    return tour.nodes[id].sequence_size;
}
fn usz marker_count(Tour* tour, int id) {
    if (id < 0) return 0;
    return tour.nodes[id].marker_count;
}
fn long node_sum(Tour* tour, int id) { return id < 0 ? 0 : tour.nodes[id].sum; }
fn void pull(Tour* tour, int id) {
    Tour_Node node = tour.nodes[id];
    tour.nodes[id].sequence_size = 1 + seq_size(tour, node.left) + seq_size(tour, node.right);
    tour.nodes[id].marker_count = (node.marker ? 1 : 0) + marker_count(tour, node.left) + marker_count(tour, node.right);
    tour.nodes[id].sum = node.own_value + node_sum(tour, node.left) + node_sum(tour, node.right);
}
fn void apply_add(Tour* tour, int id, long delta) {
    if (id < 0 || tour.nodes[id].marker_count == 0) return;
    tour.nodes[id].sum += delta * (long)tour.nodes[id].marker_count;
    if (tour.nodes[id].marker) tour.nodes[id].own_value += delta;
    tour.nodes[id].lazy_add += delta;
}
fn void push(Tour* tour, int id) {
    long delta = tour.nodes[id].lazy_add;
    if (delta == 0) return;
    apply_add(tour, tour.nodes[id].left, delta);
    apply_add(tour, tour.nodes[id].right, delta);
    tour.nodes[id].lazy_add = 0;
}
fn uint next_priority(Tour* tour) {
    uint x = tour.random_state;
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;
    tour.random_state = x;
    return x;
}
fn int new_node(Tour* tour, bool marker, long value) {
    if (tour.next_node >= MAX_TOKENS) return -1;
    int id = (int)tour.next_node++;
    tour.nodes[id] = Tour_Node{
        .left = -1, .right = -1, .parent = -1, .priority = next_priority(tour),
        .sequence_size = 1, .marker_count = marker ? 1 : 0, .marker = marker,
        .own_value = marker ? value : 0, .sum = marker ? value : 0, .lazy_add = 0,
    };
    return id;
}
fn Split split(Tour* tour, int root, usz count) {
    if (root < 0) return Split{.first = -1, .second = -1};
    push(tour, root);
    tour.nodes[root].parent = -1;
    int left = tour.nodes[root].left;
    if (seq_size(tour, left) >= count) {
        Split parts = split(tour, left, count);
        tour.nodes[root].left = parts.second;
        if (parts.second >= 0) tour.nodes[parts.second].parent = root;
        pull(tour, root);
        tour.nodes[root].parent = -1;
        return Split{.first = parts.first, .second = root};
    }
    int right = tour.nodes[root].right;
    Split parts = split(tour, right, count - seq_size(tour, left) - 1);
    tour.nodes[root].right = parts.first;
    if (parts.first >= 0) tour.nodes[parts.first].parent = root;
    pull(tour, root);
    tour.nodes[root].parent = -1;
    return Split{.first = root, .second = parts.second};
}
fn int merge(Tour* tour, int first, int second) {
    if (first < 0) { if (second >= 0) tour.nodes[second].parent = -1; return second; }
    if (second < 0) { tour.nodes[first].parent = -1; return first; }
    tour.nodes[first].parent = -1; tour.nodes[second].parent = -1;
    if (tour.nodes[first].priority >= tour.nodes[second].priority) {
        push(tour, first);
        int joined = merge(tour, tour.nodes[first].right, second);
        tour.nodes[first].right = joined;
        if (joined >= 0) tour.nodes[joined].parent = first;
        pull(tour, first); tour.nodes[first].parent = -1;
        return first;
    }
    push(tour, second);
    int joined = merge(tour, first, tour.nodes[second].left);
    tour.nodes[second].left = joined;
    if (joined >= 0) tour.nodes[joined].parent = second;
    pull(tour, second); tour.nodes[second].parent = -1;
    return second;
}
fn int root_of(Tour* tour, int id) {
    while (tour.nodes[id].parent >= 0) id = tour.nodes[id].parent;
    return id;
}
fn usz rank_of(Tour* tour, int id) {
    usz rank = seq_size(tour, tour.nodes[id].left);
    while (tour.nodes[id].parent >= 0) {
        int parent = tour.nodes[id].parent;
        if (tour.nodes[parent].right == id) rank += 1 + seq_size(tour, tour.nodes[parent].left);
        id = parent;
    }
    return rank;
}
fn int rotate_to(Tour* tour, int id) {
    Split parts = split(tour, root_of(tour, id), rank_of(tour, id));
    return merge(tour, parts.second, parts.first);
}
fn bool link_tours(Tour* tour, int[MAX_N] markers, int u, int v, int* uv, int* vu) {
    int ru = root_of(tour, markers[u]), rv = root_of(tour, markers[v]);
    if (ru == rv) return false;
    Split a = split(tour, ru, rank_of(tour, markers[u]) + 1);
    Split b = split(tour, rv, rank_of(tour, markers[v]));
    Split b2 = split(tour, b.second, 1);
    *uv = new_node(tour, false, 0); *vu = new_node(tour, false, 0);
    if (*uv < 0 || *vu < 0) return false;
    int root = merge(tour, a.first, *uv);
    root = merge(tour, root, b2.second);
    root = merge(tour, root, b.first);
    root = merge(tour, root, b2.first);
    root = merge(tour, root, *vu);
    merge(tour, root, a.second);
    return true;
}
fn bool cut_tours(Tour* tour, int uv, int vu) {
    int root = rotate_to(tour, uv);
    usz reverse_rank = rank_of(tour, vu);
    if (reverse_rank == 0) return false;
    Split p1 = split(tour, root, 1);
    Split p2 = split(tour, p1.second, reverse_rank - 1);
    Split p3 = split(tour, p2.second, 1);
    if (p1.first != uv || p3.first != vu) return false;
    tour.nodes[uv].left = -1; tour.nodes[uv].right = -1; tour.nodes[uv].parent = -1;
    tour.nodes[vu].left = -1; tour.nodes[vu].right = -1; tour.nodes[vu].parent = -1;
    return true;
}
fn bool side_operation(Tour* tour, int uv, int vu, bool update, long delta, long* answer) {
    int root = rotate_to(tour, uv);
    usz reverse_rank = rank_of(tour, vu);
    if (reverse_rank == 0) return false;
    Split p1 = split(tour, root, 1);
    Split p2 = split(tour, p1.second, reverse_rank - 1);
    if (p1.first != uv || p2.first < 0) return false;
    if (update) apply_add(tour, p2.first, delta); else *answer = node_sum(tour, p2.first);
    int joined = merge(tour, p1.first, p2.first);
    merge(tour, joined, p2.second);
    return true;
}
fn bool connected(bool[MAX_N * MAX_N] adjacency, int n, int start, int goal) {
    bool[MAX_N] seen; int[MAX_N] queue;
    for (int i = 0; i < MAX_N; i++) seen[i] = false;
    int head = 0, tail = 1; queue[0] = start; seen[start] = true;
    while (head < tail) {
        int u = queue[head++]; if (u == goal) return true;
        for (int v = 0; v < n; v++) if (adjacency[u * MAX_N + v] && !seen[v]) { seen[v] = true; queue[tail++] = v; }
    }
    return false;
}
fn bool validate_fields(long* input, int n, int q, int* queries) {
    for (int i = 0; i < n; i++) if (input[2+i] < 0 || input[2+i] > MAX_DELTA) return false;
    int edge_start = 2+n;
    for (int i = 0; i < n-1; i++) {
        long u = input[edge_start+2*i], v = input[edge_start+2*i+1];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v) return false;
    }
    int operations = edge_start+2*(n-1); *queries = 0;
    for (int i = 0; i < q; i++) {
        int at = operations+5*i;
        long kind = input[at], v = input[at+1], p = input[at+2], a = input[at+3], b = input[at+4];
        if (kind == 0) {
            if (v < 0 || v >= n || p < 0 || p >= n || a < 0 || a >= n || b < 0 || b >= n || v == p || a == b) return false;
        } else if (kind == 1) {
            if (v < 0 || v >= n || p < 0 || p >= n || v == p || a < 0 || a > MAX_DELTA || b != 0) return false;
        } else if (kind == 2) {
            if (v < 0 || v >= n || p < 0 || p >= n || v == p || a != 0 || b != 0) return false;
            (*queries)++;
        } else return false;
    }
    return true;
}
fn bool validate_topology(long* input, int n, int q) {
    bool[MAX_N * MAX_N] adjacency;
    for (int i = 0; i < MAX_N * MAX_N; i++) adjacency[i] = false;
    int edge_start = 2+n, operations = edge_start+2*(n-1);
    for (int i = 0; i < n-1; i++) {
        int u = (int)input[edge_start+2*i], v = (int)input[edge_start+2*i+1];
        if (adjacency[u*MAX_N+v]) return false;
        adjacency[u*MAX_N+v] = true; adjacency[v*MAX_N+u] = true;
    }
    for (int v = 0; v < n; v++) if (!connected(adjacency, n, 0, v)) return false;
    for (int i = 0; i < q; i++) {
        int at = operations+5*i, kind = (int)input[at], v = (int)input[at+1], p = (int)input[at+2];
        if (kind == 0) {
            int a = (int)input[at+3], b = (int)input[at+4];
            if (!adjacency[v*MAX_N+p]) return false;
            adjacency[v*MAX_N+p] = false; adjacency[p*MAX_N+v] = false;
            if (connected(adjacency, n, a, b)) return false;
            adjacency[a*MAX_N+b] = true; adjacency[b*MAX_N+a] = true;
        } else if (!adjacency[v*MAX_N+p]) return false;
    }
    return true;
}
fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset+byte] = (char)(bits >> (8*byte));
}

fn long dynamic_tree_subtree_add_subtree_sum(long* input, usz length, char* output, usz capacity)
    @export("dynamic_tree_subtree_add_subtree_sum") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 0 || q_value > (long)MAX_Q) return -1;
    int n = (int)n_value, q = (int)q_value, queries = 0;
    if (length != (usz)(3*n+5*q) || !validate_fields(input,n,q,&queries) || !validate_topology(input,n,q)) return -1;
    usz output_bytes = (usz)queries*8;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;
    Tour tour = {}; tour.random_state = 0x9e3779b9;
    int[MAX_N] markers;
    for (int i=0;i<n;i++) markers[i]=new_node(&tour,true,input[2+i]);
    int[MAX_N*MAX_N] directed;
    for (int i=0;i<MAX_N*MAX_N;i++) directed[i]=-1;
    int edge_start=2+n, operations=edge_start+2*(n-1);
    for (int i=0;i<n-1;i++) {
        int u=(int)input[edge_start+2*i], v=(int)input[edge_start+2*i+1], uv, vu;
        if (!link_tours(&tour,markers,u,v,&uv,&vu)) return -1;
        directed[u*MAX_N+v]=uv; directed[v*MAX_N+u]=vu;
    }
    long[MAX_Q] answers; int answer_count=0;
    for (int i=0;i<q;i++) {
        int at=operations+5*i, kind=(int)input[at], v=(int)input[at+1], p=(int)input[at+2];
        if (kind==0) {
            int a=(int)input[at+3], b=(int)input[at+4], uv=directed[v*MAX_N+p], vu=directed[p*MAX_N+v];
            if (uv<0 || vu<0 || !cut_tours(&tour,uv,vu)) return -1;
            directed[v*MAX_N+p]=-1; directed[p*MAX_N+v]=-1;
            int nuv,nvu; if (!link_tours(&tour,markers,a,b,&nuv,&nvu)) return -1;
            directed[a*MAX_N+b]=nuv; directed[b*MAX_N+a]=nvu;
        } else if (kind==1) {
            long ignored=0;
            if (!side_operation(&tour,directed[p*MAX_N+v],directed[v*MAX_N+p],true,input[at+3],&ignored)) return -1;
        } else {
            long answer=0;
            if (!side_operation(&tour,directed[p*MAX_N+v],directed[v*MAX_N+p],false,0,&answer)) return -1;
            answers[answer_count++]=answer;
        }
    }
    if (output_bytes>0) for (int i=0;i<answer_count;i++) put_i64(output,(usz)i*8,answers[i]);
    return (long)output_bytes;
}
