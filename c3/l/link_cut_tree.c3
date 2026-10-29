module link_cut_tree;

const usz MAX_N = 16;
const usz MAX_Q = 64;
const usz MAX_INPUT = 2 + MAX_N + 3 * MAX_Q;

struct LctNode { int left; int right; int parent; bool reversed; long value; long sum; }

fn bool lct_is_root(LctNode* nodes, int x) {
    int p = nodes[x].parent;
    return p < 0 || (nodes[p].left != x && nodes[p].right != x);
}
fn void lct_pull(LctNode* nodes, int x) {
    long left_sum = nodes[x].left < 0 ? 0 : nodes[nodes[x].left].sum;
    long right_sum = nodes[x].right < 0 ? 0 : nodes[nodes[x].right].sum;
    nodes[x].sum = nodes[x].value + left_sum + right_sum;
}
fn void lct_reverse(LctNode* nodes, int x) {
    if (x < 0) return;
    int temp = nodes[x].left; nodes[x].left = nodes[x].right; nodes[x].right = temp;
    nodes[x].reversed = !nodes[x].reversed;
}
fn void lct_push(LctNode* nodes, int x) {
    if (!nodes[x].reversed) return;
    lct_reverse(nodes, nodes[x].left); lct_reverse(nodes, nodes[x].right);
    nodes[x].reversed = false;
}
fn void lct_rotate(LctNode* nodes, int x) {
    int p = nodes[x].parent, g = nodes[p].parent;
    bool right_child = nodes[p].right == x;
    int middle = right_child ? nodes[x].left : nodes[x].right;
    if (!lct_is_root(nodes, p)) {
        if (nodes[g].left == p) nodes[g].left = x; else nodes[g].right = x;
    }
    nodes[x].parent = g;
    if (right_child) { nodes[x].left = p; nodes[p].right = middle; }
    else { nodes[x].right = p; nodes[p].left = middle; }
    nodes[p].parent = x;
    if (middle >= 0) nodes[middle].parent = p;
    lct_pull(nodes, p); lct_pull(nodes, x);
}
fn void lct_splay(LctNode* nodes, int x) {
    int[MAX_N] stack; int count = 0, y = x;
    stack[count++] = y;
    while (!lct_is_root(nodes, y)) { y = nodes[y].parent; stack[count++] = y; }
    while (count > 0) lct_push(nodes, stack[--count]);
    while (!lct_is_root(nodes, x)) {
        int p = nodes[x].parent;
        if (!lct_is_root(nodes, p)) {
            int g = nodes[p].parent;
            bool zigzig = (nodes[p].left == x) == (nodes[g].left == p);
            lct_rotate(nodes, zigzig ? p : x);
        }
        lct_rotate(nodes, x);
    }
}
fn void lct_access(LctNode* nodes, int x) {
    int last = -1;
    for (int y = x; y >= 0; y = nodes[y].parent) {
        lct_splay(nodes, y); nodes[y].right = last;
        if (last >= 0) nodes[last].parent = y;
        lct_pull(nodes, y); last = y;
    }
    lct_splay(nodes, x);
}
fn void lct_make_root(LctNode* nodes, int x) { lct_access(nodes, x); lct_reverse(nodes, x); }
fn int lct_find_root(LctNode* nodes, int x) {
    lct_access(nodes, x); lct_push(nodes, x);
    while (nodes[x].left >= 0) { x = nodes[x].left; lct_push(nodes, x); }
    lct_splay(nodes, x); return x;
}
fn int lct_link(LctNode* nodes, int u, int v) {
    if (u == v) return 0;
    lct_make_root(nodes, u);
    if (lct_find_root(nodes, v) == u) return 0;
    nodes[u].parent = v; return 1;
}
fn int lct_cut(LctNode* nodes, int u, int v) {
    if (u == v) return 0;
    lct_make_root(nodes, u); lct_access(nodes, v);
    if (nodes[v].left != u || nodes[u].right >= 0) return 0;
    nodes[v].left = -1; nodes[u].parent = -1; lct_pull(nodes, v); return 1;
}
fn long lct_path_sum(LctNode* nodes, int u, int v) {
    lct_make_root(nodes, u);
    if (lct_find_root(nodes, v) != u) return -1;
    lct_make_root(nodes, u); lct_access(nodes, v); return nodes[v].sum;
}
fn void lct_put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long link_cut_tree(long* input, usz input_length, char* output, usz output_capacity)
    @export("link_cut_tree") {
    if (input == null || input_length < 2 || input_length > MAX_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 1 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (input_length != 2 + n + 3 * q) return -1;
    for (usz vertex = 0; vertex < n; vertex++)
        if (input[2 + vertex] < 0 || input[2 + vertex] > 1000000) return -1;
    usz operations_at = 2 + n;
    for (usz i = 0; i < q; i++) {
        long op = input[operations_at + 3 * i], u = input[operations_at + 3 * i + 1];
        long v = input[operations_at + 3 * i + 2];
        if (op < 0 || op > 2 || u < 0 || u >= n_value || v < 0 || v >= n_value) return -1;
    }
    usz bytes = 8 * q;
    if (output == null || output_capacity < bytes) return -2;
    LctNode[MAX_N] nodes;
    for (usz i = 0; i < n; i++) {
        nodes[i].left = -1; nodes[i].right = -1; nodes[i].parent = -1;
        nodes[i].reversed = false; nodes[i].value = input[2 + i]; nodes[i].sum = nodes[i].value;
    }
    for (usz i = 0; i < q; i++) {
        usz at = operations_at + 3 * i;
        int op = (int)input[at], u = (int)input[at + 1], v = (int)input[at + 2];
        long result = op == 0 ? (long)lct_link(&nodes[0], u, v)
                     : op == 1 ? (long)lct_cut(&nodes[0], u, v)
                               : lct_path_sum(&nodes[0], u, v);
        lct_put_i64(output, 8 * i, result);
    }
    return (long)bytes;
}
