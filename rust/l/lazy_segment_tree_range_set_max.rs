const MAX_N: usize = 256;
const MAX_Q: usize = 512;
const MAX_INPUT: usize = 2306;

fn build(node: usize, left: usize, right: usize, values: &[i64], tree: &mut [i64; 1024]) {
    if left == right { tree[node] = values[left]; return; }
    let mid = left + (right - left) / 2;
    build(node * 2, left, mid, values, tree);
    build(node * 2 + 1, mid + 1, right, values, tree);
    tree[node] = tree[node * 2].max(tree[node * 2 + 1]);
}
fn push(node: usize, left: usize, right: usize, tree: &mut [i64; 1024], lazy: &mut [i64; 1024], pending: &mut [bool; 1024]) {
    if !pending[node] { return; }
    tree[node] = lazy[node]; pending[node] = false;
    if left != right { let a = node * 2; lazy[a] = tree[node]; lazy[a + 1] = tree[node]; pending[a] = true; pending[a + 1] = true; }
}
fn assign_range(node: usize, left: usize, right: usize, ql: usize, qr: usize, value: i64,
                tree: &mut [i64; 1024], lazy: &mut [i64; 1024], pending: &mut [bool; 1024]) {
    push(node, left, right, tree, lazy, pending);
    if right < ql || left > qr { return; }
    if ql <= left && right <= qr {
        tree[node] = value;
        if left != right { let a = node * 2; lazy[a] = value; lazy[a + 1] = value; pending[a] = true; pending[a + 1] = true; }
        return;
    }
    let mid = left + (right - left) / 2;
    assign_range(node * 2, left, mid, ql, qr, value, tree, lazy, pending);
    assign_range(node * 2 + 1, mid + 1, right, ql, qr, value, tree, lazy, pending);
    tree[node] = tree[node * 2].max(tree[node * 2 + 1]);
}
fn range_max(node: usize, left: usize, right: usize, ql: usize, qr: usize,
             tree: &mut [i64; 1024], lazy: &mut [i64; 1024], pending: &mut [bool; 1024]) -> i64 {
    push(node, left, right, tree, lazy, pending);
    if right < ql || left > qr { return i64::MIN; }
    if ql <= left && right <= qr { return tree[node]; }
    let mid = left + (right - left) / 2;
    range_max(node * 2, left, mid, ql, qr, tree, lazy, pending)
        .max(range_max(node * 2 + 1, mid + 1, right, ql, qr, tree, lazy, pending))
}

#[no_mangle]
pub extern "C" fn lazy_segment_tree_range_set_max(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let (nv, qv) = (packed[0], packed[1]);
    if !(1..=MAX_N as i64).contains(&nv) || !(0..=MAX_Q as i64).contains(&qv) { return -1; }
    let (n, q) = (nv as usize, qv as usize);
    if length < 2 + n { return -1; }
    let initial = &packed[2..2 + n];
    if initial.iter().any(|&x| !(-1_000_000..=1_000_000).contains(&x)) { return -1; }
    let mut offset = 2 + n;
    let mut opcodes = [0u8; MAX_Q]; let mut lefts = [0usize; MAX_Q]; let mut rights = [0usize; MAX_Q]; let mut assigned = [0i64; MAX_Q];
    for i in 0..q {
        if offset >= length { return -1; }
        let op = packed[offset];
        let width = match op { 0 => 3, 1 => 4, _ => return -1 };
        if offset + width > length { return -1; }
        let (l, r) = (packed[offset + 1], packed[offset + 2]);
        if l < 0 || l >= r || r > nv { return -1; }
        opcodes[i] = op as u8; lefts[i] = l as usize; rights[i] = r as usize;
        if op == 1 { assigned[i] = packed[offset + 3]; if !(-1_000_000..=1_000_000).contains(&assigned[i]) { return -1; } }
        offset += width;
    }
    if offset != length { return -1; }
    let mut tree = [0i64; 1024]; let mut lazy = [0i64; 1024]; let mut pending = [false; 1024];
    build(1, 0, n - 1, initial, &mut tree);
    let mut checksum = 0i64; let mut ordinal = 0i64;
    for i in 0..q {
        if opcodes[i] == 1 { assign_range(1, 0, n - 1, lefts[i], rights[i] - 1, assigned[i], &mut tree, &mut lazy, &mut pending); }
        else { let answer = range_max(1, 0, n - 1, lefts[i], rights[i] - 1, &mut tree, &mut lazy, &mut pending); ordinal += 1; checksum += ordinal * (answer + 1_000_001); }
    }
    checksum
}
