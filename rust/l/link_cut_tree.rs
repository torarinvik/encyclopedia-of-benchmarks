const MAX_N: usize = 16;
const MAX_Q: usize = 64;
const MAX_INPUT: usize = 210;

#[derive(Clone, Copy)]
struct Node {
    child: [i32; 2],
    parent: i32,
    reversed: bool,
    value: i64,
    sum: i64,
}

fn is_aux_root(nodes: &[Node; MAX_N], x: usize) -> bool {
    let parent = nodes[x].parent;
    parent < 0 || (nodes[parent as usize].child[0] != x as i32 && nodes[parent as usize].child[1] != x as i32)
}
fn pull(nodes: &mut [Node; MAX_N], x: usize) {
    let left = nodes[x].child[0];
    let right = nodes[x].child[1];
    nodes[x].sum = nodes[x].value
        + if left < 0 { 0 } else { nodes[left as usize].sum }
        + if right < 0 { 0 } else { nodes[right as usize].sum };
}
fn toggle_reverse(nodes: &mut [Node; MAX_N], x: i32) {
    if x < 0 { return; }
    let node = &mut nodes[x as usize];
    node.child.swap(0, 1);
    node.reversed = !node.reversed;
}
fn push(nodes: &mut [Node; MAX_N], x: usize) {
    if !nodes[x].reversed { return; }
    let left = nodes[x].child[0];
    let right = nodes[x].child[1];
    toggle_reverse(nodes, left);
    toggle_reverse(nodes, right);
    nodes[x].reversed = false;
}
fn rotate(nodes: &mut [Node; MAX_N], x: usize) {
    let p = nodes[x].parent as usize;
    let g = nodes[p].parent;
    let direction = if nodes[p].child[1] == x as i32 { 1 } else { 0 };
    let middle = nodes[x].child[direction ^ 1];
    if !is_aux_root(nodes, p) {
        let g_index = g as usize;
        let side = if nodes[g_index].child[1] == p as i32 { 1 } else { 0 };
        nodes[g_index].child[side] = x as i32;
    }
    nodes[x].parent = g;
    nodes[x].child[direction ^ 1] = p as i32;
    nodes[p].parent = x as i32;
    nodes[p].child[direction] = middle;
    if middle >= 0 { nodes[middle as usize].parent = p as i32; }
    pull(nodes, p);
    pull(nodes, x);
}
fn splay(nodes: &mut [Node; MAX_N], x: usize) {
    let mut stack = [0usize; MAX_N];
    let mut count = 1usize;
    let mut y = x;
    stack[0] = y;
    while !is_aux_root(nodes, y) {
        y = nodes[y].parent as usize;
        stack[count] = y;
        count += 1;
    }
    while count > 0 { count -= 1; push(nodes, stack[count]); }
    while !is_aux_root(nodes, x) {
        let p = nodes[x].parent as usize;
        if !is_aux_root(nodes, p) {
            let g = nodes[p].parent as usize;
            let zig_zig = (nodes[p].child[0] == x as i32) == (nodes[g].child[0] == p as i32);
            rotate(nodes, if zig_zig { p } else { x });
        }
        rotate(nodes, x);
    }
}
fn access(nodes: &mut [Node; MAX_N], x: usize) {
    let mut last = -1i32;
    let mut y = x as i32;
    while y >= 0 {
        let yi = y as usize;
        splay(nodes, yi);
        nodes[yi].child[1] = last;
        if last >= 0 { nodes[last as usize].parent = y; }
        pull(nodes, yi);
        last = y;
        y = nodes[yi].parent;
    }
    splay(nodes, x);
}
fn make_root(nodes: &mut [Node; MAX_N], x: usize) {
    access(nodes, x);
    toggle_reverse(nodes, x as i32);
}
fn find_root(nodes: &mut [Node; MAX_N], x: usize) -> usize {
    access(nodes, x);
    push(nodes, x);
    let mut root = x;
    while nodes[root].child[0] >= 0 {
        root = nodes[root].child[0] as usize;
        push(nodes, root);
    }
    splay(nodes, root);
    root
}
fn link_nodes(nodes: &mut [Node; MAX_N], u: usize, v: usize) -> i64 {
    if u == v { return 0; }
    make_root(nodes, u);
    if find_root(nodes, v) == u { return 0; }
    nodes[u].parent = v as i32;
    1
}
fn cut_nodes(nodes: &mut [Node; MAX_N], u: usize, v: usize) -> i64 {
    if u == v { return 0; }
    make_root(nodes, u);
    access(nodes, v);
    if nodes[v].child[0] != u as i32 || nodes[u].child[1] >= 0 { return 0; }
    nodes[v].child[0] = -1;
    nodes[u].parent = -1;
    pull(nodes, v);
    1
}
fn path_sum(nodes: &mut [Node; MAX_N], u: usize, v: usize) -> i64 {
    make_root(nodes, u);
    if find_root(nodes, v) != u { return -1; }
    make_root(nodes, u);
    access(nodes, v);
    nodes[v].sum
}
unsafe fn put_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn link_cut_tree(input: *const i64, input_length: usize,
                                         output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input, input_length);
    let n_value = input[0];
    let q_value = input[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(1..=MAX_Q as i64).contains(&q_value) { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if input_length != 2 + n + 3 * q { return -1; }
    if input[2..2 + n].iter().any(|&weight| !(0..=1_000_000).contains(&weight)) { return -1; }
    let operations_at = 2 + n;
    for i in 0..q {
        let at = operations_at + 3 * i;
        let op = input[at];
        let u = input[at + 1];
        let v = input[at + 2];
        if !(0..=2).contains(&op) || u < 0 || u >= n_value || v < 0 || v >= n_value { return -1; }
    }
    if output.is_null() || output_capacity < 8 * q { return -2; }
    let mut nodes = [Node { child: [-1; 2], parent: -1, reversed: false, value: 0, sum: 0 }; MAX_N];
    for i in 0..n { nodes[i].value = input[2 + i]; nodes[i].sum = nodes[i].value; }
    for i in 0..q {
        let at = operations_at + 3 * i;
        let op = input[at] as usize;
        let u = input[at + 1] as usize;
        let v = input[at + 2] as usize;
        let result = match op {
            0 => link_nodes(&mut nodes, u, v),
            1 => cut_nodes(&mut nodes, u, v),
            _ => path_sum(&mut nodes, u, v),
        };
        put_i64(output, 8 * i, result);
    }
    (8 * q) as i64
}
