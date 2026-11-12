module dynamic_tree_vertex_add_subtree_sum;

const usz MAX_N = 32;
const usz MAX_Q = 64;
const usz MAX_INPUT = 3 * MAX_N + 5 * MAX_Q + 1;
const long MAX_VALUE = 1000;

struct LctNode { int left; int right; int parent; bool reversed; long value; long virtual_sum; long sum; }

fn bool lct_is_root(LctNode* nodes, int x) {
    int p = nodes[x].parent;
    return p < 0 || (nodes[p].left != x && nodes[p].right != x);
}
fn long lct_sum(LctNode* nodes, int x) { return x < 0 ? 0 : nodes[x].sum; }
fn void lct_pull(LctNode* nodes, int x) {
    nodes[x].sum = nodes[x].value + nodes[x].virtual_sum +
        lct_sum(nodes, nodes[x].left) + lct_sum(nodes, nodes[x].right);
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
        lct_splay(nodes, y);
        int old_right = nodes[y].right;
        nodes[y].virtual_sum += lct_sum(nodes, old_right) - lct_sum(nodes, last);
        nodes[y].right = last;
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
fn bool lct_link(LctNode* nodes, int u, int v) {
    if (u == v) return false;
    lct_make_root(nodes, u);
    if (lct_find_root(nodes, v) == u) return false;
    lct_access(nodes, v);
    nodes[u].parent = v;
    nodes[v].virtual_sum += nodes[u].sum;
    lct_pull(nodes, v);
    return true;
}
fn bool lct_cut(LctNode* nodes, int u, int v) {
    if (u == v) return false;
    lct_make_root(nodes, u); lct_access(nodes, v);
    if (nodes[v].left != u || nodes[u].right >= 0) return false;
    nodes[v].left = -1; nodes[u].parent = -1; lct_pull(nodes, v);
    return true;
}
fn long lct_subtree_sum(LctNode* nodes, int vertex, int parent) {
    lct_make_root(nodes, parent); lct_access(nodes, vertex);
    if (nodes[vertex].left != parent || nodes[parent].right >= 0) return -1;
    return nodes[vertex].value + nodes[vertex].virtual_sum;
}
fn void lct_put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long dynamic_tree_vertex_add_subtree_sum(long* input, usz length, char* output, usz capacity)
    @export("dynamic_tree_vertex_add_subtree_sum") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 0 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 3 * n + 5 * q) return -1;
    for (usz i = 0; i < n; i++) if (input[2 + i] < 0 || input[2 + i] > MAX_VALUE) return -1;
    usz edge_start = 2 + n, operation_start = edge_start + 2 * (n - 1);
    for (usz i = 0; i < n - 1; i++) {
        long u = input[edge_start + 2 * i], v = input[edge_start + 2 * i + 1];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value || u == v) return -1;
    }
    for (usz i = 0; i < q; i++) {
        usz at = operation_start + 5 * i;
        long kind = input[at], a = input[at + 1], b = input[at + 2];
        long c = input[at + 3], d = input[at + 4];
        if (kind == 0) {
            if (a < 0 || a >= n_value || b < 0 || b >= n_value || c < 0 || c >= n_value || d < 0 || d >= n_value || a == b || c == d) return -1;
        } else if (kind == 1) {
            if (a < 0 || a >= n_value || b < 0 || b > MAX_VALUE || c != 0 || d != 0) return -1;
        } else if (kind == 2) {
            if (a < 0 || a >= n_value || b < 0 || b >= n_value || c != 0 || d != 0) return -1;
        } else return -1;
    }
    LctNode[MAX_N] nodes;
    for (usz i = 0; i < n; i++) {
        nodes[i].left = -1; nodes[i].right = -1; nodes[i].parent = -1;
        nodes[i].reversed = false; nodes[i].value = input[2 + i];
        nodes[i].virtual_sum = 0; nodes[i].sum = nodes[i].value;
    }
    for (usz i = 0; i < n - 1; i++)
        if (!lct_link(&nodes[0], (int)input[edge_start + 2 * i], (int)input[edge_start + 2 * i + 1])) return -1;
    long[MAX_Q] answers;
    usz answer_count = 0;
    for (usz i = 0; i < q; i++) {
        usz at = operation_start + 5 * i;
        int kind = (int)input[at], a = (int)input[at + 1], b = (int)input[at + 2];
        if (kind == 0) {
            int c = (int)input[at + 3], d = (int)input[at + 4];
            if (!lct_cut(&nodes[0], a, b) || !lct_link(&nodes[0], c, d)) return -1;
        } else if (kind == 1) {
            lct_access(&nodes[0], a); nodes[a].value += b; lct_pull(&nodes[0], a);
        } else {
            long result = lct_subtree_sum(&nodes[0], a, b);
            if (result < 0) return -1;
            answers[answer_count++] = result;
        }
    }
    usz output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;
    for (usz i = 0; i < answer_count; i++) lct_put_i64(output, 8 * i, answers[i]);
    return (long)output_bytes;
}
