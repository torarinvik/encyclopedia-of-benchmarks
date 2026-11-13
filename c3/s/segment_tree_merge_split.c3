module segment_tree_merge_split;

const usz DOMAIN = 64, MAX_Q = 32, MAX_ROOTS = 33, MAX_NODES = 1024;
const usz MAX_INPUT = 131, MAX_OUTPUT = 256;

struct Node { int left; int right; long total; }
struct Operation { long op; long a; long b; long c; }

fn int allocate(Node[MAX_NODES]* nodes, usz* used) {
    if (*used >= MAX_NODES) return -1;
    int id = (int)(*used);
    *used += 1;
    (*nodes)[(usz)id] = Node{0, 0, 0};
    return id;
}
fn int insert(Node[MAX_NODES]* nodes, usz* used, int node, int lo, int hi, int value, long amount) {
    if (node == 0) { node = allocate(nodes, used); if (node < 0) return -1; }
    if (lo == hi) { (*nodes)[(usz)node].total += amount; return node; }
    int mid = (lo + hi) / 2;
    if (value <= mid) {
        int child = insert(nodes, used, (*nodes)[(usz)node].left, lo, mid, value, amount);
        if (child < 0) return -1;
        (*nodes)[(usz)node].left = child;
    } else {
        int child = insert(nodes, used, (*nodes)[(usz)node].right, mid + 1, hi, value, amount);
        if (child < 0) return -1;
        (*nodes)[(usz)node].right = child;
    }
    int left = (*nodes)[(usz)node].left, right = (*nodes)[(usz)node].right;
    (*nodes)[(usz)node].total = (*nodes)[(usz)left].total + (*nodes)[(usz)right].total;
    return node;
}
fn int merge_nodes(Node[MAX_NODES]* nodes, int a, int b, int lo, int hi) {
    if (a == 0) return b;
    if (b == 0) return a;
    if (lo == hi) { (*nodes)[(usz)a].total += (*nodes)[(usz)b].total; return a; }
    int mid = (lo + hi) / 2;
    int al = (*nodes)[(usz)a].left, ar = (*nodes)[(usz)a].right;
    int bl = (*nodes)[(usz)b].left, br = (*nodes)[(usz)b].right;
    (*nodes)[(usz)a].left = merge_nodes(nodes, al, bl, lo, mid);
    (*nodes)[(usz)a].right = merge_nodes(nodes, ar, br, mid + 1, hi);
    int left = (*nodes)[(usz)a].left, right = (*nodes)[(usz)a].right;
    (*nodes)[(usz)a].total = (*nodes)[(usz)left].total + (*nodes)[(usz)right].total;
    return a;
}
fn int split(Node[MAX_NODES]* nodes, usz* used, int node, int lo, int hi,
             int ql, int qr, int* moved) {
    *moved = 0;
    if (node == 0 || qr < lo || hi < ql) return node;
    if (ql <= lo && hi <= qr) { *moved = node; return 0; }
    int mid = (lo + hi) / 2, ml = 0, mr = 0;
    int old_left = (*nodes)[(usz)node].left, old_right = (*nodes)[(usz)node].right;
    int remain_left = split(nodes, used, old_left, lo, mid, ql, qr, &ml);
    if (remain_left < 0) return -1;
    int remain_right = split(nodes, used, old_right, mid + 1, hi, ql, qr, &mr);
    if (remain_right < 0) return -1;
    (*nodes)[(usz)node].left = remain_left;
    (*nodes)[(usz)node].right = remain_right;
    (*nodes)[(usz)node].total = (*nodes)[(usz)remain_left].total + (*nodes)[(usz)remain_right].total;
    if (ml != 0 || mr != 0) {
        *moved = allocate(nodes, used);
        if (*moved < 0) return -1;
        (*nodes)[(usz)*moved].left = ml;
        (*nodes)[(usz)*moved].right = mr;
        (*nodes)[(usz)*moved].total = (*nodes)[(usz)ml].total + (*nodes)[(usz)mr].total;
    }
    return node;
}
fn long range_sum(Node[MAX_NODES]* nodes, int node, int lo, int hi, int ql, int qr) {
    if (node == 0 || qr < lo || hi < ql) return 0;
    if (ql <= lo && hi <= qr) return (*nodes)[(usz)node].total;
    int mid = (lo + hi) / 2;
    return range_sum(nodes, (*nodes)[(usz)node].left, lo, mid, ql, qr)
         + range_sum(nodes, (*nodes)[(usz)node].right, mid + 1, hi, ql, qr);
}
fn long kth(Node[MAX_NODES]* nodes, int node, int lo, int hi, long k) {
    if (node == 0 || k > (*nodes)[(usz)node].total) return -1;
    if (lo == hi) return lo;
    int mid = (lo + hi) / 2, left = (*nodes)[(usz)node].left;
    if (k <= (*nodes)[(usz)left].total) return kth(nodes, left, lo, mid, k);
    return kth(nodes, (*nodes)[(usz)node].right, mid + 1, hi, k - (*nodes)[(usz)left].total);
}
fn void pack_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i++) output[offset + i] = (char)((bits >> (8 * i)) & 255);
}

long segment_tree_merge_split(long* input, usz length, char* output, usz capacity)
        @export("segment_tree_merge_split") {
    if (input == null || length < 2 || length > MAX_INPUT || input[0] != (long)DOMAIN
        || input[1] < 0 || input[1] > (long)MAX_Q) return -1;
    usz q = (usz)input[1];
    if (length != 2 + 4 * q) return -1;
    Operation[MAX_Q] ops = zeroed;
    usz roots_count = 1;
    for (usz i = 0; i < q; i++) {
        long op = input[2 + 4*i], a = input[3 + 4*i], b = input[4 + 4*i], c = input[5 + 4*i];
        bool a_ok = a >= 0 && (usz)a < roots_count;
        bool valid = false;
        if (op == 0) valid = a_ok && b >= 1 && b <= 64 && c >= 1 && c <= 10;
        else if (op == 1) {
            valid = a_ok && b >= 1 && b <= c && c <= 64 && roots_count < MAX_ROOTS;
            if (valid) roots_count++;
        } else if (op == 2) valid = a_ok && a != b && b >= 0 && (usz)b < roots_count && c == 0;
        else if (op == 3) valid = a_ok && b >= 1 && b <= c && c <= 64;
        else if (op == 4) valid = a_ok && b >= 1 && b <= 320 && c == 0;
        if (!valid) return -1;
        ops[i] = Operation{op, a, b, c};
    }
    Node[MAX_NODES] nodes = zeroed;
    int[MAX_ROOTS] roots = zeroed;
    char[MAX_OUTPUT] staged = zeroed;
    usz used = 1, root_count = 1, bytes = 0;
    for (usz i = 0; i < q; i++) {
        Operation item = ops[i];
        usz a = (usz)item.a;
        if (item.op == 0) {
            int updated = insert(&nodes, &used, roots[a], 1, 64, (int)item.b, item.c);
            if (updated < 0) return -1;
            roots[a] = updated;
        } else if (item.op == 1) {
            int moved = 0;
            int remain = split(&nodes, &used, roots[a], 1, 64, (int)item.b, (int)item.c, &moved);
            if (remain < 0) return -1;
            roots[a] = remain; roots[root_count++] = moved;
        } else if (item.op == 2) {
            usz b = (usz)item.b;
            roots[a] = merge_nodes(&nodes, roots[a], roots[b], 1, 64); roots[b] = 0;
        } else if (item.op == 3) {
            pack_i64(staged, bytes, range_sum(&nodes, roots[a], 1, 64, (int)item.b, (int)item.c)); bytes += 8;
        } else {
            pack_i64(staged, bytes, kth(&nodes, roots[a], 1, 64, item.b)); bytes += 8;
        }
    }
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < bytes; i++) output[i] = staged[i];
    return (long)bytes;
}
