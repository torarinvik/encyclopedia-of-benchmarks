const DOMAIN: i64 = 64;
const MAX_Q: usize = 32;
const MAX_ROOTS: usize = 33;
const MAX_NODES: usize = 1024;
const MAX_INPUT: usize = 131;
const MAX_OUTPUT: usize = 256;

#[repr(C)]
#[derive(Clone, Copy, Default)]
struct Node { left: i32, right: i32, total: i64 }
#[derive(Clone, Copy, Default)]
struct Operation { op: i64, a: i64, b: i64, c: i64 }

fn allocate(nodes: &mut [Node; MAX_NODES], used: &mut usize) -> i32 {
    if *used >= MAX_NODES { return -1; }
    let id = *used;
    *used += 1;
    nodes[id] = Node::default();
    id as i32
}

fn insert(nodes: &mut [Node; MAX_NODES], used: &mut usize, mut node: i32,
          lo: i32, hi: i32, value: i32, amount: i64) -> i32 {
    if node == 0 { node = allocate(nodes, used); if node < 0 { return -1; } }
    let ix = node as usize;
    if lo == hi { nodes[ix].total += amount; return node; }
    let mid = (lo + hi) / 2;
    if value <= mid {
        let old = nodes[ix].left;
        let child = insert(nodes, used, old, lo, mid, value, amount);
        if child < 0 { return -1; }
        nodes[ix].left = child;
    } else {
        let old = nodes[ix].right;
        let child = insert(nodes, used, old, mid + 1, hi, value, amount);
        if child < 0 { return -1; }
        nodes[ix].right = child;
    }
    let left = nodes[ix].left as usize;
    let right = nodes[ix].right as usize;
    nodes[ix].total = nodes[left].total + nodes[right].total;
    node
}

fn merge_nodes(nodes: &mut [Node; MAX_NODES], a: i32, b: i32, lo: i32, hi: i32) -> i32 {
    if a == 0 { return b; }
    if b == 0 { return a; }
    let ai = a as usize;
    let bi = b as usize;
    if lo == hi { nodes[ai].total += nodes[bi].total; return a; }
    let mid = (lo + hi) / 2;
    let al = nodes[ai].left; let ar = nodes[ai].right;
    let bl = nodes[bi].left; let br = nodes[bi].right;
    nodes[ai].left = merge_nodes(nodes, al, bl, lo, mid);
    nodes[ai].right = merge_nodes(nodes, ar, br, mid + 1, hi);
    let left = nodes[ai].left as usize; let right = nodes[ai].right as usize;
    nodes[ai].total = nodes[left].total + nodes[right].total;
    a
}

fn split(nodes: &mut [Node; MAX_NODES], used: &mut usize, node: i32,
          lo: i32, hi: i32, ql: i32, qr: i32) -> (i32, i32) {
    if node == 0 || qr < lo || hi < ql { return (node, 0); }
    if ql <= lo && hi <= qr { return (0, node); }
    let ix = node as usize;
    let mid = (lo + hi) / 2;
    let old_left = nodes[ix].left; let old_right = nodes[ix].right;
    let (remain_left, moved_left) = split(nodes, used, old_left, lo, mid, ql, qr);
    if remain_left < 0 { return (-1, 0); }
    let (remain_right, moved_right) = split(nodes, used, old_right, mid + 1, hi, ql, qr);
    if remain_right < 0 { return (-1, 0); }
    nodes[ix].left = remain_left; nodes[ix].right = remain_right;
    let rl = remain_left as usize; let rr = remain_right as usize;
    nodes[ix].total = nodes[rl].total + nodes[rr].total;
    let mut moved = 0;
    if moved_left != 0 || moved_right != 0 {
        moved = allocate(nodes, used);
        if moved < 0 { return (-1, 0); }
        let mi = moved as usize;
        nodes[mi].left = moved_left; nodes[mi].right = moved_right;
        nodes[mi].total = nodes[moved_left as usize].total + nodes[moved_right as usize].total;
    }
    (node, moved)
}

fn range_sum(nodes: &[Node; MAX_NODES], node: i32, lo: i32, hi: i32, ql: i32, qr: i32) -> i64 {
    if node == 0 || qr < lo || hi < ql { return 0; }
    let ix = node as usize;
    if ql <= lo && hi <= qr { return nodes[ix].total; }
    let mid = (lo + hi) / 2;
    range_sum(nodes, nodes[ix].left, lo, mid, ql, qr)
        + range_sum(nodes, nodes[ix].right, mid + 1, hi, ql, qr)
}

fn kth(nodes: &[Node; MAX_NODES], node: i32, lo: i32, hi: i32, k: i64) -> i64 {
    if node == 0 || k > nodes[node as usize].total { return -1; }
    if lo == hi { return lo as i64; }
    let ix = node as usize; let mid = (lo + hi) / 2;
    let left = nodes[ix].left;
    if k <= nodes[left as usize].total { kth(nodes, left, lo, mid, k) }
    else { kth(nodes, nodes[ix].right, mid + 1, hi, k - nodes[left as usize].total) }
}

unsafe fn run(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] != DOMAIN || values[1] < 0 || values[1] > MAX_Q as i64 { return -1; }
    let q = values[1] as usize;
    if length != 2 + 4 * q { return -1; }
    let mut ops = [Operation::default(); MAX_Q];
    let mut roots_count = 1usize;
    for i in 0..q {
        let (op, a, b, c) = (values[2+4*i], values[3+4*i], values[4+4*i], values[5+4*i]);
        let a_ok = a >= 0 && (a as usize) < roots_count;
        let b_ok = b >= 0 && (b as usize) < roots_count;
        let valid = match op {
            0 => a_ok && (1..=DOMAIN).contains(&b) && (1..=10).contains(&c),
            1 => {
                let ok = a_ok && b >= 1 && b <= c && c <= DOMAIN && roots_count < MAX_ROOTS;
                if ok { roots_count += 1; }
                ok
            }
            2 => a_ok && b_ok && a != b && c == 0,
            3 => a_ok && b >= 1 && b <= c && c <= DOMAIN,
            4 => a_ok && (1..=320).contains(&b) && c == 0,
            _ => false,
        };
        if !valid { return -1; }
        ops[i] = Operation { op, a, b, c };
    }
    let mut nodes = [Node::default(); MAX_NODES];
    let mut roots = [0_i32; MAX_ROOTS];
    let mut staged = [0_u8; MAX_OUTPUT];
    let (mut used, mut root_count, mut bytes) = (1usize, 1usize, 0usize);
    for item in ops.iter().take(q) {
        let a = item.a as usize;
        let answer;
        match item.op {
            0 => {
                let updated = insert(&mut nodes, &mut used, roots[a], 1, DOMAIN as i32, item.b as i32, item.c);
                if updated < 0 { return -1; }
                roots[a] = updated;
                continue;
            }
            1 => {
                let (remain, moved) = split(&mut nodes, &mut used, roots[a], 1, DOMAIN as i32, item.b as i32, item.c as i32);
                if remain < 0 || moved < 0 { return -1; }
                roots[a] = remain; roots[root_count] = moved; root_count += 1;
                continue;
            }
            2 => {
                let b = item.b as usize;
                roots[a] = merge_nodes(&mut nodes, roots[a], roots[b], 1, DOMAIN as i32); roots[b] = 0;
                continue;
            }
            3 => answer = range_sum(&nodes, roots[a], 1, DOMAIN as i32, item.b as i32, item.c as i32),
            _ => answer = kth(&nodes, roots[a], 1, DOMAIN as i32, item.b),
        }
        staged[bytes..bytes+8].copy_from_slice(&answer.to_le_bytes());
        bytes += 8;
    }
    if output.is_null() || capacity < bytes { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}

#[no_mangle]
pub unsafe extern "C" fn segment_tree_merge_split(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    run(input, length, output, capacity)
}
