const MAX_N: usize = 64;
const MAX_Q: usize = 32;
const TREE_N: usize = 4 * MAX_N + 5;
const MOD: i64 = 998_244_353;

#[derive(Clone, Copy, Default)]
struct Affine { a: i64, b: i64 }
#[derive(Clone, Copy, Default)]
struct Node { value: Affine, lazy: Affine, has_lazy: bool }
#[derive(Clone, Copy, Default)]
struct Operation { kind: i64, left: usize, right: usize, x: i64, y: i64 }

fn compose(after: Affine, before: Affine) -> Affine {
    Affine { a: after.a * before.a % MOD, b: (after.a * before.b + after.b) % MOD }
}
fn power_map(a: i64, b: i64, mut exponent: usize) -> Affine {
    let mut result = Affine { a: 1, b: 0 };
    let mut base = Affine { a, b };
    while exponent > 0 {
        if exponent & 1 != 0 { result = compose(base, result); }
        base = compose(base, base);
        exponent >>= 1;
    }
    result
}
fn build(tree: &mut [Node; TREE_N], node: usize, left: usize, right: usize,
         initial_a: &[i64; MAX_N], initial_b: &[i64; MAX_N]) {
    if right - left == 1 {
        tree[node].value = Affine { a: initial_a[left], b: initial_b[left] };
        return;
    }
    let mid = left + (right - left) / 2;
    build(tree, node * 2, left, mid, initial_a, initial_b);
    build(tree, node * 2 + 1, mid, right, initial_a, initial_b);
    tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value);
}
fn apply(tree: &mut [Node; TREE_N], node: usize, left: usize, right: usize, a: i64, b: i64) {
    tree[node].value = power_map(a, b, right - left);
    tree[node].lazy = Affine { a, b };
    tree[node].has_lazy = true;
}
fn push(tree: &mut [Node; TREE_N], node: usize, left: usize, right: usize) {
    if !tree[node].has_lazy || right - left == 1 { return; }
    let mid = left + (right - left) / 2;
    let tag = tree[node].lazy;
    apply(tree, node * 2, left, mid, tag.a, tag.b);
    apply(tree, node * 2 + 1, mid, right, tag.a, tag.b);
    tree[node].has_lazy = false;
}
fn update(tree: &mut [Node; TREE_N], node: usize, left: usize, right: usize,
          ql: usize, qr: usize, a: i64, b: i64) {
    if ql <= left && right <= qr { apply(tree, node, left, right, a, b); return; }
    push(tree, node, left, right);
    let mid = left + (right - left) / 2;
    if ql < mid { update(tree, node * 2, left, mid, ql, qr, a, b); }
    if qr > mid { update(tree, node * 2 + 1, mid, right, ql, qr, a, b); }
    tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value);
}
fn query(tree: &mut [Node; TREE_N], node: usize, left: usize, right: usize,
         ql: usize, qr: usize) -> Affine {
    if ql <= left && right <= qr { return tree[node].value; }
    push(tree, node, left, right);
    let mid = left + (right - left) / 2;
    if qr <= mid { return query(tree, node * 2, left, mid, ql, qr); }
    if ql >= mid { return query(tree, node * 2 + 1, mid, right, ql, qr); }
    compose(query(tree, node * 2 + 1, mid, right, ql, qr),
            query(tree, node * 2, left, mid, ql, qr))
}
unsafe fn put_i64_le(out: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *out.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn range_set_range_composite(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 291 { return -1; }
    let n64 = *input;
    let q64 = *input.add(1);
    if n64 < 1 || n64 > 64 || q64 < 1 || q64 > 32 { return -1; }
    let n = n64 as usize;
    let q = q64 as usize;
    if length < 2 + 2 * n { return -1; }
    let mut initial_a = [0i64; MAX_N];
    let mut initial_b = [0i64; MAX_N];
    let mut offset = 2;
    for i in 0..n {
        initial_a[i] = *input.add(offset);
        initial_b[i] = *input.add(offset + 1);
        offset += 2;
        if initial_a[i] < 1 || initial_a[i] >= MOD || initial_b[i] < 0 || initial_b[i] >= MOD { return -1; }
    }
    let mut operations = [Operation::default(); MAX_Q];
    let mut query_count = 0usize;
    for k in 0..q {
        if offset >= length { return -1; }
        let kind = *input.add(offset);
        offset += 1;
        if kind == 0 {
            if offset + 4 > length { return -1; }
            let l = *input.add(offset); let r = *input.add(offset + 1);
            let a = *input.add(offset + 2); let b = *input.add(offset + 3); offset += 4;
            if l < 0 || l >= r || r > n64 || a < 1 || a >= MOD || b < 0 || b >= MOD { return -1; }
            operations[k] = Operation { kind, left: l as usize, right: r as usize, x: a, y: b };
        } else if kind == 1 {
            if offset + 3 > length { return -1; }
            let l = *input.add(offset); let r = *input.add(offset + 1); let x = *input.add(offset + 2); offset += 3;
            if l < 0 || l >= r || r > n64 || x < 0 || x >= MOD { return -1; }
            operations[k] = Operation { kind, left: l as usize, right: r as usize, x, y: 0 };
            query_count += 1;
        } else { return -1; }
    }
    if offset != length { return -1; }
    let mut tree = [Node::default(); TREE_N];
    build(&mut tree, 1, 0, n, &initial_a, &initial_b);
    let mut answers = [0i64; MAX_Q];
    let mut answer_index = 0;
    for op in operations.iter().take(q) {
        if op.kind == 0 { update(&mut tree, 1, 0, n, op.left, op.right, op.x, op.y); }
        else { let value = query(&mut tree, 1, 0, n, op.left, op.right); answers[answer_index] = (value.a * op.x + value.b) % MOD; answer_index += 1; }
    }
    let bytes = 8 * query_count;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..query_count { put_i64_le(output, 8 * i, answers[i]); }
    bytes as i64
}
