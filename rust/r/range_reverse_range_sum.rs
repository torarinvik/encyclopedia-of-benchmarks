const MAX_N: usize = 64;
const MAX_Q: usize = 32;
const MAX_INPUT: usize = 163;

#[derive(Clone, Copy, Default)]
struct Node { left: i32, right: i32, size: usize, value: i64, sum: i64, priority: u64, reversed: bool }
#[derive(Clone, Copy, Default)]
struct Operation { kind: i64, left: usize, right: usize }

fn priority_for(index: usize) -> u64 {
    let mut state = 1i64;
    for _ in 0..=index { state = (state * 48271) % 2_147_483_647; }
    state as u64
}
fn size(t: &[Node; MAX_N], x: i32) -> usize { if x < 0 { 0 } else { t[x as usize].size } }
fn sum(t: &[Node; MAX_N], x: i32) -> i64 { if x < 0 { 0 } else { t[x as usize].sum } }
fn higher(t: &[Node; MAX_N], a: i32, b: i32) -> bool {
    let x = t[a as usize]; let y = t[b as usize];
    if x.priority != y.priority { x.priority > y.priority } else { a > b }
}
fn pull(t: &mut [Node; MAX_N], x: i32) {
    let i = x as usize;
    t[i].size = 1 + size(t, t[i].left) + size(t, t[i].right);
    t[i].sum = t[i].value + sum(t, t[i].left) + sum(t, t[i].right);
}
fn reverse_node(t: &mut [Node; MAX_N], x: i32) {
    if x < 0 { return; }
    let n = &mut t[x as usize];
    core::mem::swap(&mut n.left, &mut n.right);
    n.reversed = !n.reversed;
}
fn push(t: &mut [Node; MAX_N], x: i32) {
    if !t[x as usize].reversed { return; }
    let left = t[x as usize].left; let right = t[x as usize].right;
    reverse_node(t, left); reverse_node(t, right); t[x as usize].reversed = false;
}
fn split(t: &mut [Node; MAX_N], root: i32, count: usize) -> (i32, i32) {
    if root < 0 { return (-1, -1); }
    push(t, root);
    let i = root as usize;
    if size(t, t[i].left) >= count {
        let (a, b) = split(t, t[i].left, count);
        t[i].left = b; pull(t, root); (a, root)
    } else {
        let (a, b) = split(t, t[i].right, count - size(t, t[i].left) - 1);
        t[i].right = a; pull(t, root); (root, b)
    }
}
fn merge(t: &mut [Node; MAX_N], a: i32, b: i32) -> i32 {
    if a < 0 { return b; }
    if b < 0 { return a; }
    if higher(t, a, b) {
        push(t, a); let i = a as usize; let child = t[i].right;
        t[i].right = merge(t, child, b); pull(t, a); a
    } else {
        push(t, b); let i = b as usize; let child = t[i].left;
        t[i].left = merge(t, a, child); pull(t, b); b
    }
}
unsafe fn put64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for j in 0..8 { *output.add(offset + j) = (bits >> (8 * j)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn range_reverse_range_sum(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input; let q64 = *input.add(1);
    if n64 < 0 || n64 > MAX_N as i64 || q64 < 0 || q64 > MAX_Q as i64 { return -1; }
    let n = n64 as usize; let q = q64 as usize; let mut offset = 2;
    if length < 2 + n { return -1; }
    let mut nodes = [Node::default(); MAX_N];
    for i in 0..n {
        let value = *input.add(offset); offset += 1;
        if !(0..=1_000_000_000).contains(&value) { return -1; }
        nodes[i] = Node { left: -1, right: -1, size: 1, value, sum: value, priority: priority_for(i), reversed: false };
    }
    let mut ops = [Operation::default(); MAX_Q]; let mut query_count = 0;
    for i in 0..q {
        if offset + 3 > length { return -1; }
        let kind = *input.add(offset); let left = *input.add(offset + 1); let right = *input.add(offset + 2); offset += 3;
        if (kind != 0 && kind != 1) || left < 0 || left > right || right > n64 { return -1; }
        ops[i] = Operation { kind, left: left as usize, right: right as usize };
        if kind == 1 { query_count += 1; }
    }
    if offset != length { return -1; }
    let mut root = -1;
    for i in 0..n { root = merge(&mut nodes, root, i as i32); }
    let mut answers = [0i64; MAX_Q]; let mut answer_count = 0;
    for op in ops.iter().take(q) {
        let (prefix, suffix) = split(&mut nodes, root, op.right);
        let (prefix, middle) = split(&mut nodes, prefix, op.left);
        if op.kind == 0 { reverse_node(&mut nodes, middle); }
        else { answers[answer_count] = sum(&nodes, middle); answer_count += 1; }
        root = merge(&mut nodes, merge(&mut nodes, prefix, middle), suffix);
    }
    let bytes = 8 * query_count;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..query_count { put64(output, 8 * i, answers[i]); }
    bytes as i64
}
