const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_INPUT: usize = 322;
const NODE_CAP: usize = 640;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

#[derive(Clone, Copy)]
struct Node { sum: i64, left: i32, right: i32 }

fn make_node(nodes: &mut [Node; NODE_CAP], used: &mut usize, sum: i64, left: i32, right: i32) -> i32 {
    if *used >= NODE_CAP { return -1; }
    let index = *used as i32; nodes[*used] = Node { sum, left, right }; *used += 1; index
}
fn build(nodes: &mut [Node; NODE_CAP], used: &mut usize, values: &[i64], left: usize, right: usize) -> i32 {
    if left == right { return make_node(nodes, used, values[left], -1, -1); }
    let mid = left + (right - left) / 2;
    let a = build(nodes, used, values, left, mid); let b = build(nodes, used, values, mid + 1, right);
    if a < 0 || b < 0 { return -1; }
    make_node(nodes, used, nodes[a as usize].sum + nodes[b as usize].sum, a, b)
}
fn point_set(nodes: &mut [Node; NODE_CAP], used: &mut usize, root: i32, left: usize, right: usize, index: usize, value: i64) -> i32 {
    if left == right { return make_node(nodes, used, value, -1, -1); }
    let mid = left + (right - left) / 2;
    let mut a = nodes[root as usize].left; let mut b = nodes[root as usize].right;
    if index <= mid { a = point_set(nodes, used, a, left, mid, index, value); }
    else { b = point_set(nodes, used, b, mid + 1, right, index, value); }
    if a < 0 || b < 0 { return -1; }
    make_node(nodes, used, nodes[a as usize].sum + nodes[b as usize].sum, a, b)
}
fn range_sum(nodes: &[Node; NODE_CAP], node: i32, left: usize, right: usize, ql: usize, qr: usize) -> i64 {
    if ql <= left && right <= qr { return nodes[node as usize].sum; }
    let mid = left + (right - left) / 2; let mut total = 0;
    if ql <= mid { total += range_sum(nodes, nodes[node as usize].left, left, mid, ql, qr); }
    if qr > mid { total += range_sum(nodes, nodes[node as usize].right, mid + 1, right, ql, qr); }
    total
}
fn hash_word(mut hash: u64, value: i64) -> u64 {
    for byte in value.to_le_bytes() { hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME); }
    hash
}

#[no_mangle]
pub extern "C" fn persistent_segment_tree(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let (n64, q64) = (input[0], input[1]);
    if n64 < 1 || n64 > MAX_N as i64 || q64 < 0 || q64 > MAX_Q as i64 { return -1; }
    let (n, q) = (n64 as usize, q64 as usize);
    if length != 2 + n + 4 * q { return -1; }
    let values = &input[2..2 + n];
    if values.iter().any(|&v| !(-1000..=1000).contains(&v)) { return -1; }
    let mut nodes = [Node { sum: 0, left: -1, right: -1 }; NODE_CAP]; let mut used = 0;
    let mut roots = [0i32; MAX_Q + 1]; roots[0] = build(&mut nodes, &mut used, values, 0, n - 1);
    if roots[0] < 0 { return -1; }
    let mut version_count = 1usize; let mut query_count = 0usize; let mut query_sums = [0i64; MAX_Q];
    let mut offset = 2 + n;
    for _ in 0..q {
        let (op, a, b, c) = (input[offset], input[offset + 1], input[offset + 2], input[offset + 3]); offset += 4;
        if op == 0 {
            if a < 0 || a as usize >= version_count || b < 0 || b >= n64 || !(-1000..=1000).contains(&c) { return -1; }
            let next = point_set(&mut nodes, &mut used, roots[a as usize], 0, n - 1, b as usize, c);
            if next < 0 { return -1; } roots[version_count] = next; version_count += 1;
        } else if op == 1 {
            if a < 0 || a as usize >= version_count || b < 0 || c < b || c >= n64 { return -1; }
            query_sums[query_count] = range_sum(&nodes, roots[a as usize], 0, n - 1, b as usize, c as usize); query_count += 1;
        } else { return -1; }
    }
    let mut hash = hash_word(FNV_OFFSET, version_count as i64);
    hash = hash_word(hash, query_count as i64);
    for &sum in &query_sums[..query_count] { hash = hash_word(hash, sum); }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}
