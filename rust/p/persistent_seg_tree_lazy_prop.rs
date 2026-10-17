const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + MAX_N + 4 * MAX_Q + 1;
const NODE_CAP: usize = 16384;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

#[derive(Clone, Copy)]
struct Node { sum: i64, prop: i64, left: i32, right: i32 }

fn make_node(nodes: &mut [Node; NODE_CAP], used: &mut usize,
             sum: i64, prop: i64, left: i32, right: i32) -> i32 {
    if *used >= NODE_CAP { return -1; }
    let index = *used as i32;
    nodes[*used] = Node { sum, prop, left, right };
    *used += 1;
    index
}

fn clone_node(nodes: &mut [Node; NODE_CAP], used: &mut usize, source: i32) -> i32 {
    if source < 0 || *used >= NODE_CAP { return -1; }
    let index = *used as i32;
    nodes[*used] = nodes[source as usize];
    *used += 1;
    index
}

fn push_lazy(nodes: &mut [Node; NODE_CAP], used: &mut usize,
             node: i32, left: usize, right: usize) -> bool {
    let prop = nodes[node as usize].prop;
    if prop == 0 { return true; }
    nodes[node as usize].sum += (right - left + 1) as i64 * prop;
    if left != right {
        let new_left = clone_node(nodes, used, nodes[node as usize].left);
        let new_right = clone_node(nodes, used, nodes[node as usize].right);
        if new_left < 0 || new_right < 0 { return false; }
        nodes[node as usize].left = new_left;
        nodes[node as usize].right = new_right;
        nodes[new_left as usize].prop += prop;
        nodes[new_right as usize].prop += prop;
    }
    nodes[node as usize].prop = 0;
    true
}

fn build(nodes: &mut [Node; NODE_CAP], used: &mut usize, values: &[i64],
         left: usize, right: usize) -> i32 {
    if left == right { return make_node(nodes, used, values[left], 0, -1, -1); }
    let mid = left + (right - left) / 2;
    let a = build(nodes, used, values, left, mid);
    let b = build(nodes, used, values, mid + 1, right);
    if a < 0 || b < 0 { return -1; }
    make_node(nodes, used, nodes[a as usize].sum + nodes[b as usize].sum, 0, a, b)
}

fn update(nodes: &mut [Node; NODE_CAP], used: &mut usize, current: i32,
          left: usize, right: usize, ql: usize, qr: usize, delta: i64) -> i32 {
    if !push_lazy(nodes, used, current, left, right) { return -1; }
    if left >= ql && right <= qr {
        let copy = clone_node(nodes, used, current);
        if copy < 0 { return -1; }
        nodes[copy as usize].prop += delta;
        if !push_lazy(nodes, used, copy, left, right) { return -1; }
        return copy;
    }
    if left > qr || right < ql { return current; }
    let copy = make_node(nodes, used, 0, 0, -1, -1);
    if copy < 0 { return -1; }
    let mid = left + (right - left) / 2;
    let a = update(nodes, used, nodes[current as usize].left, left, mid, ql, qr, delta);
    let b = update(nodes, used, nodes[current as usize].right, mid + 1, right, ql, qr, delta);
    if a < 0 || b < 0 { return -1; }
    nodes[copy as usize].left = a;
    nodes[copy as usize].right = b;
    nodes[copy as usize].sum = nodes[a as usize].sum + nodes[b as usize].sum;
    copy
}

fn query(nodes: &mut [Node; NODE_CAP], used: &mut usize, node: i32,
         left: usize, right: usize, ql: usize, qr: usize) -> Result<i64, ()> {
    if !push_lazy(nodes, used, node, left, right) { return Err(()); }
    if right < ql || qr < left { return Ok(0); }
    if ql <= left && right <= qr { return Ok(nodes[node as usize].sum); }
    let mid = left + (right - left) / 2;
    let a = query(nodes, used, nodes[node as usize].left, left, mid, ql, qr)?;
    let b = query(nodes, used, nodes[node as usize].right, mid + 1, right, ql, qr)?;
    Ok(a + b)
}

fn hash_word(mut hash: u64, value: i64) -> u64 {
    for byte in value.to_le_bytes() { hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME); }
    hash
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let n64 = input[0];
    let q64 = input[1];
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_Q as i64).contains(&q64) { return Err(()); }
    let n = n64 as usize;
    let q = q64 as usize;
    if input.len() != 2 + n + 4 * q { return Err(()); }
    let values = &input[2..2 + n];
    if values.iter().any(|value| !(-1000..=1000).contains(value)) { return Err(()); }

    let mut nodes = [Node { sum: 0, prop: 0, left: -1, right: -1 }; NODE_CAP];
    let mut used = 0usize;
    let mut roots = [0i32; MAX_Q + 1];
    roots[0] = build(&mut nodes, &mut used, values, 0, n - 1);
    if roots[0] < 0 { return Err(()); }
    let (mut version_count, mut query_count) = (1usize, 0usize);
    let mut query_sums = [0i64; MAX_Q];
    let mut offset = 2 + n;

    for _ in 0..q {
        let (op, a, b, c) = (input[offset], input[offset + 1], input[offset + 2], input[offset + 3]);
        offset += 4;
        if op == 0 {
            if a < 0 || a > b || b >= n64 || !(-1000..=1000).contains(&c) { return Err(()); }
            let next = update(&mut nodes, &mut used, roots[version_count - 1], 0, n - 1,
                              a as usize, b as usize, c);
            if next < 0 { return Err(()); }
            roots[version_count] = next;
            version_count += 1;
        } else if op == 1 {
            if a < 0 || a as usize >= version_count || b < 0 || c < b || c >= n64 { return Err(()); }
            query_sums[query_count] = query(&mut nodes, &mut used, roots[a as usize],
                                             0, n - 1, b as usize, c as usize)?;
            query_count += 1;
        } else { return Err(()); }
    }

    let mut hash = hash_word(FNV_OFFSET, version_count as i64);
    hash = hash_word(hash, query_count as i64);
    for &sum in &query_sums[..query_count] { hash = hash_word(hash, sum); }
    Ok((hash & 0x7fff_ffff_ffff_ffff) as i64)
}

#[no_mangle]
pub unsafe extern "C" fn persistent_seg_tree_lazy_prop(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
