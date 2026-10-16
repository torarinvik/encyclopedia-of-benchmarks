module persistent_segment_tree;

const int MAX_N = 64;
const int MAX_Q = 64;
const int MAX_INPUT = 322;
const int NODE_CAP = 640;
const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;
struct Node { long sum; int left; int right; }

fn int make_node(Node* nodes, usz* used, long sum, int left, int right) {
    if (*used >= NODE_CAP) return -1;
    int index = (int)*used;
    nodes[*used] = {sum, left, right};
    *used += 1;
    return index;
}
fn int build(Node* nodes, usz* used, long* values, usz left, usz right) {
    if (left == right) return make_node(nodes, used, values[left], -1, -1);
    usz mid = left + (right - left) / 2;
    int a = build(nodes, used, values, left, mid);
    int b = build(nodes, used, values, mid + 1, right);
    if (a < 0 || b < 0) return -1;
    return make_node(nodes, used, nodes[(usz)a].sum + nodes[(usz)b].sum, a, b);
}
fn int point_set(Node* nodes, usz* used, int root, usz left, usz right, usz index, long value) {
    if (left == right) return make_node(nodes, used, value, -1, -1);
    usz mid = left + (right - left) / 2;
    int a = nodes[(usz)root].left, b = nodes[(usz)root].right;
    if (index <= mid) a = point_set(nodes, used, a, left, mid, index, value);
    else b = point_set(nodes, used, b, mid + 1, right, index, value);
    if (a < 0 || b < 0) return -1;
    return make_node(nodes, used, nodes[(usz)a].sum + nodes[(usz)b].sum, a, b);
}
fn long range_sum(Node* nodes, int node, usz left, usz right, usz ql, usz qr) {
    if (ql <= left && right <= qr) return nodes[(usz)node].sum;
    usz mid = left + (right - left) / 2;
    long total = 0;
    if (ql <= mid) total += range_sum(nodes, nodes[(usz)node].left, left, mid, ql, qr);
    if (qr > mid) total += range_sum(nodes, nodes[(usz)node].right, mid + 1, right, ql, qr);
    return total;
}
fn ulong hash_word(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (usz shift = 0; shift < 64; shift += 8) hash = (hash ^ (ulong)(uint8)(bits >> shift)) * FNV_PRIME;
    return hash;
}

fn long persistent_segment_tree(long* input, usz length) @export("persistent_segment_tree") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q) return -1;
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
            if (a < 0 || (ulong)a >= version_count || b < 0 || b >= n64 || c < -1000 || c > 1000) return -1;
            int next = point_set(&nodes[0], &used, roots[(usz)a], 0, n - 1, (usz)b, c);
            if (next < 0) return -1;
            roots[version_count++] = next;
        } else if (op == 1) {
            if (a < 0 || (ulong)a >= version_count || b < 0 || c < b || c >= n64) return -1;
            query_sums[query_count++] = range_sum(&nodes[0], roots[(usz)a], 0, n - 1, (usz)b, (usz)c);
        } else return -1;
    }
    ulong hash = hash_word(FNV_OFFSET, (long)version_count);
    hash = hash_word(hash, (long)query_count);
    for (usz i = 0; i < query_count; i++) hash = hash_word(hash, query_sums[i]);
    return (long)(hash & 0x7fffffffffffffff);
}
