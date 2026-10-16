module lazy_segment_tree_range_set_max;

const usz MAX_N = 256, MAX_Q = 512, MAX_INPUT = 2306;
const long OFFSET = 1000001;

fn void build(usz node, usz left, usz right, long* values, long* tree) {
    if (left == right) { tree[node] = values[left]; return; }
    usz mid = left + (right - left) / 2;
    build(node * 2, left, mid, values, tree);
    build(node * 2 + 1, mid + 1, right, values, tree);
    tree[node] = tree[node * 2] > tree[node * 2 + 1] ? tree[node * 2] : tree[node * 2 + 1];
}
fn void push(usz node, usz left, usz right, long* tree, long* lazy, bool* pending) {
    if (!pending[node]) return;
    tree[node] = lazy[node]; pending[node] = false;
    if (left != right) {
        usz a = node * 2;
        lazy[a] = tree[node]; lazy[a + 1] = tree[node];
        pending[a] = true; pending[a + 1] = true;
    }
}
fn void assign_range(usz node, usz left, usz right, usz ql, usz qr, long value,
                     long* tree, long* lazy, bool* pending) {
    push(node, left, right, tree, lazy, pending);
    if (right < ql || left > qr) return;
    if (ql <= left && right <= qr) {
        tree[node] = value;
        if (left != right) { usz a = node * 2; lazy[a] = value; lazy[a + 1] = value; pending[a] = true; pending[a + 1] = true; }
        return;
    }
    usz mid = left + (right - left) / 2;
    assign_range(node * 2, left, mid, ql, qr, value, tree, lazy, pending);
    assign_range(node * 2 + 1, mid + 1, right, ql, qr, value, tree, lazy, pending);
    tree[node] = tree[node * 2] > tree[node * 2 + 1] ? tree[node * 2] : tree[node * 2 + 1];
}
fn long range_max(usz node, usz left, usz right, usz ql, usz qr,
                 long* tree, long* lazy, bool* pending) {
    push(node, left, right, tree, lazy, pending);
    if (right < ql || left > qr) return -9223372036854775807 - 1;
    if (ql <= left && right <= qr) return tree[node];
    usz mid = left + (right - left) / 2;
    long a = range_max(node * 2, left, mid, ql, qr, tree, lazy, pending);
    long b = range_max(node * 2 + 1, mid + 1, right, ql, qr, tree, lazy, pending);
    return a > b ? a : b;
}

fn long lazy_segment_tree_range_set_max(long* packed, usz length) @export("lazy_segment_tree_range_set_max") {
    if (packed == null || length < 2 || length > MAX_INPUT) return -1;
    long nv = packed[0], qv = packed[1];
    if (nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q) return -1;
    usz n = (usz)nv, q = (usz)qv;
    if (length < 2 + n) return -1;
    long[MAX_N] initial;
    for (usz i = 0; i < n; i++) { initial[i] = packed[2 + i]; if (initial[i] < -1000000 || initial[i] > 1000000) return -1; }
    usz offset = 2 + n;
    uint8[MAX_Q] opcode;
    usz[MAX_Q] lefts, rights;
    long[MAX_Q] assigned;
    for (usz i = 0; i < q; i++) {
        if (offset >= length) return -1;
        long op = packed[offset];
        usz width = op == 0 ? 3 : op == 1 ? 4 : 0;
        if (width == 0 || offset + width > length) return -1;
        long l = packed[offset + 1], r = packed[offset + 2];
        if (l < 0 || l >= r || r > nv) return -1;
        opcode[i] = (uint8)op; lefts[i] = (usz)l; rights[i] = (usz)r; assigned[i] = 0;
        if (op == 1) { assigned[i] = packed[offset + 3]; if (assigned[i] < -1000000 || assigned[i] > 1000000) return -1; }
        offset += width;
    }
    if (offset != length) return -1;
    long[1024] tree = zeroed, lazy = zeroed;
    bool[1024] pending = zeroed;
    build(1, 0, n - 1, &initial[0], &tree[0]);
    long checksum = 0, ordinal = 0;
    for (usz i = 0; i < q; i++) {
        if (opcode[i] == 1) assign_range(1, 0, n - 1, lefts[i], rights[i] - 1, assigned[i], &tree[0], &lazy[0], &pending[0]);
        else { long answer = range_max(1, 0, n - 1, lefts[i], rights[i] - 1, &tree[0], &lazy[0], &pending[0]); ordinal++; checksum += ordinal * (answer + OFFSET); }
    }
    return checksum;
}
