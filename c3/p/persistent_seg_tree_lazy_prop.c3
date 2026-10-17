module persistent_seg_tree_lazy_prop;

const int MAX_N = 64;
const int MAX_Q = 64;
const int MAX_INPUT = 323;
const int NODE_CAP = 16384;
const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

struct Node { long sum; long prop; int left; int right; }

fn int make_node(Node* nodes, usz* used, long sum, long prop, int left, int right) {
    if (*used >= NODE_CAP) return -1;
    int index = (int)*used;
    nodes[*used] = {sum, prop, left, right};
    *used += 1;
    return index;
}

fn int clone_node(Node* nodes, usz* used, int source) {
    if (source < 0 || *used >= NODE_CAP) return -1;
    int index = (int)*used;
    nodes[*used] = nodes[(usz)source];
    *used += 1;
    return index;
}

fn bool push_lazy(Node* nodes, usz* used, int node, usz left, usz right) {
    long prop = nodes[(usz)node].prop;
    if (prop == 0) return true;
    nodes[(usz)node].sum += (long)(right - left + 1) * prop;
    if (left != right) {
        int new_left = clone_node(nodes, used, nodes[(usz)node].left);
        int new_right = clone_node(nodes, used, nodes[(usz)node].right);
        if (new_left < 0 || new_right < 0) return false;
        nodes[(usz)node].left = new_left;
        nodes[(usz)node].right = new_right;
        nodes[(usz)new_left].prop += prop;
        nodes[(usz)new_right].prop += prop;
    }
    nodes[(usz)node].prop = 0;
    return true;
}

fn int build(Node* nodes, usz* used, long* values, usz left, usz right) {
    if (left == right) return make_node(nodes, used, values[left], 0, -1, -1);
    usz mid = left + (right - left) / 2;
    int a = build(nodes, used, values, left, mid);
    int b = build(nodes, used, values, mid + 1, right);
    if (a < 0 || b < 0) return -1;
    return make_node(nodes, used, nodes[(usz)a].sum + nodes[(usz)b].sum, 0, a, b);
}

fn int range_add(Node* nodes, usz* used, int current, usz left, usz right,
                 usz ql, usz qr, long delta) {
    if (!push_lazy(nodes, used, current, left, right)) return -1;
    if (left >= ql && right <= qr) {
        int copy = clone_node(nodes, used, current);
        if (copy < 0) return -1;
        nodes[(usz)copy].prop += delta;
        if (!push_lazy(nodes, used, copy, left, right)) return -1;
        return copy;
    }
    if (left > qr || right < ql) return current;
    int copy = make_node(nodes, used, 0, 0, -1, -1);
    if (copy < 0) return -1;
    usz mid = left + (right - left) / 2;
    int a = range_add(nodes, used, nodes[(usz)current].left, left, mid, ql, qr, delta);
    int b = range_add(nodes, used, nodes[(usz)current].right, mid + 1, right, ql, qr, delta);
    if (a < 0 || b < 0) return -1;
    nodes[(usz)copy].left = a;
    nodes[(usz)copy].right = b;
    nodes[(usz)copy].sum = nodes[(usz)a].sum + nodes[(usz)b].sum;
    return copy;
}

fn long range_sum(Node* nodes, usz* used, int node, usz left, usz right,
                  usz ql, usz qr, bool* ok) {
    if (!push_lazy(nodes, used, node, left, right)) { *ok = false; return 0; }
    if (right < ql || qr < left) return 0;
    if (ql <= left && right <= qr) return nodes[(usz)node].sum;
    usz mid = left + (right - left) / 2;
    long a = range_sum(nodes, used, nodes[(usz)node].left, left, mid, ql, qr, ok);
    if (!*ok) return 0;
    long b = range_sum(nodes, used, nodes[(usz)node].right, mid + 1, right, ql, qr, ok);
    return a + b;
}

fn ulong hash_word(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (usz shift = 0; shift < (usz)64; shift += (usz)8)
        hash = (hash ^ (ulong)(uint8)(bits >> shift)) * FNV_PRIME;
    return hash;
}

fn long persistent_seg_tree_lazy_prop(long* input, usz length) @export("persistent_seg_tree_lazy_prop") {
    if (input == null || length < (usz)2 || length > (usz)MAX_INPUT) return -1;
    long n64 = input[0], q64 = input[1];
    if (n64 < (long)1 || n64 > (long)MAX_N || q64 < (long)0 || q64 > (long)MAX_Q) return -1;
    usz n = (usz)n64, q = (usz)q64;
    if (length != 2 + n + 4 * q) return -1;
    for (usz i = 0; i < n; i++) if (input[2 + i] < -1000 || input[2 + i] > 1000) return -1;

    Node[NODE_CAP] nodes;
    usz used = 0;
    int[MAX_Q + 1] roots;
    roots[0] = build(&nodes[0], &used, &input[2], 0, n - 1);
    if (roots[0] < 0) return -1;
    usz version_count = 1, query_count = 0, offset = 2 + n;
    long[MAX_Q] query_sums;
    for (usz i = 0; i < q; i++) {
        long op = input[offset], a = input[offset + 1], b = input[offset + 2], c = input[offset + 3];
        offset += 4;
        if (op == 0) {
            if (a < 0 || a > b || b >= n64 || c < -1000 || c > 1000) return -1;
            int next = range_add(&nodes[0], &used, roots[version_count - 1], 0, n - 1,
                                 (usz)a, (usz)b, c);
            if (next < 0) return -1;
            roots[version_count++] = next;
        } else if (op == 1) {
            if (a < 0 || (usz)a >= version_count || b < 0 || c < b || c >= n64) return -1;
            bool ok = true;
            query_sums[query_count] = range_sum(&nodes[0], &used, roots[(usz)a], 0, n - 1,
                                                 (usz)b, (usz)c, &ok);
            if (!ok) return -1;
            query_count++;
        } else return -1;
    }

    ulong hash = hash_word(FNV_OFFSET, (long)version_count);
    hash = hash_word(hash, (long)query_count);
    for (usz i = 0; i < query_count; i++) hash = hash_word(hash, query_sums[i]);
    return (long)(hash & 0x7fffffffffffffff);
}
