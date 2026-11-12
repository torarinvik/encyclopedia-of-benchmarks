const MAX_N: usize = 32;
const MAX_Q: usize = 64;
const MAX_INPUT: usize = 3 * MAX_N + 5 * MAX_Q + 1;
const MAX_VALUE: i64 = 1_000;

#[derive(Clone, Copy)]
struct Node {
    child: [i32; 2],
    parent: i32,
    reversed: bool,
    value: i64,
    virtual_sum: i64,
    sum: i64,
}

fn is_aux_root(nodes: &[Node; MAX_N], x: usize) -> bool {
    let p = nodes[x].parent;
    p < 0 || (nodes[p as usize].child[0] != x as i32 && nodes[p as usize].child[1] != x as i32)
}
fn node_sum(nodes: &[Node; MAX_N], x: i32) -> i64 {
    if x < 0 { 0 } else { nodes[x as usize].sum }
}
fn pull(nodes: &mut [Node; MAX_N], x: usize) {
    let left = node_sum(nodes, nodes[x].child[0]);
    let right = node_sum(nodes, nodes[x].child[1]);
    nodes[x].sum = nodes[x].value + nodes[x].virtual_sum + left + right;
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
    let direction = usize::from(nodes[p].child[1] == x as i32);
    let middle = nodes[x].child[direction ^ 1];
    if !is_aux_root(nodes, p) {
        let gp = g as usize;
        let side = usize::from(nodes[gp].child[1] == p as i32);
        nodes[gp].child[side] = x as i32;
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
            let zigzig = (nodes[p].child[0] == x as i32) == (nodes[g].child[0] == p as i32);
            rotate(nodes, if zigzig { p } else { x });
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
        let old_right = nodes[yi].child[1];
        let delta = node_sum(nodes, old_right) - node_sum(nodes, last);
        nodes[yi].virtual_sum += delta;
        nodes[yi].child[1] = last;
        if last >= 0 { nodes[last as usize].parent = y; }
        pull(nodes, yi);
        last = y;
        y = nodes[yi].parent;
    }
    splay(nodes, x);
}
fn make_root(nodes: &mut [Node; MAX_N], x: usize) { access(nodes, x); toggle_reverse(nodes, x as i32); }
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
fn link_nodes(nodes: &mut [Node; MAX_N], u: usize, v: usize) -> bool {
    if u == v { return false; }
    make_root(nodes, u);
    if find_root(nodes, v) == u { return false; }
    access(nodes, v);
    nodes[u].parent = v as i32;
    nodes[v].virtual_sum += nodes[u].sum;
    pull(nodes, v);
    true
}
fn cut_nodes(nodes: &mut [Node; MAX_N], u: usize, v: usize) -> bool {
    if u == v { return false; }
    make_root(nodes, u);
    access(nodes, v);
    if nodes[v].child[0] != u as i32 || nodes[u].child[1] >= 0 { return false; }
    nodes[v].child[0] = -1;
    nodes[u].parent = -1;
    pull(nodes, v);
    true
}
fn subtree_side_sum(nodes: &mut [Node; MAX_N], vertex: usize, parent: usize) -> Option<i64> {
    make_root(nodes, parent);
    access(nodes, vertex);
    if nodes[vertex].child[0] != parent as i32 || nodes[parent].child[1] >= 0 { return None; }
    Some(nodes[vertex].value + nodes[vertex].virtual_sum)
}
unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn dynamic_tree_vertex_add_subtree_sum(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input, input_length);
    let n_value = input[0];
    let q_value = input[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if input_length != 3 * n + 5 * q { return -1; }
    if input[2..2 + n].iter().any(|&v| !(0..=MAX_VALUE).contains(&v)) { return -1; }
    let edge_start = 2 + n;
    let operation_start = edge_start + 2 * (n - 1);
    for i in 0..n - 1 {
        let u = input[edge_start + 2 * i];
        let v = input[edge_start + 2 * i + 1];
        if u < 0 || u >= n_value || v < 0 || v >= n_value || u == v { return -1; }
    }
    for i in 0..q {
        let at = operation_start + 5 * i;
        let (kind, a, b, c, d) = (input[at], input[at + 1], input[at + 2], input[at + 3], input[at + 4]);
        if kind == 0 {
            if a < 0 || a >= n_value || b < 0 || b >= n_value || c < 0 || c >= n_value || d < 0 || d >= n_value || a == b || c == d { return -1; }
        } else if kind == 1 {
            if a < 0 || a >= n_value || b < 0 || b > MAX_VALUE || c != 0 || d != 0 { return -1; }
        } else if kind == 2 {
            if a < 0 || a >= n_value || b < 0 || b >= n_value || c != 0 || d != 0 { return -1; }
        } else { return -1; }
    }
    let mut nodes = [Node { child: [-1; 2], parent: -1, reversed: false, value: 0, virtual_sum: 0, sum: 0 }; MAX_N];
    for i in 0..n { nodes[i].value = input[2 + i]; nodes[i].sum = input[2 + i]; }
    for i in 0..n - 1 {
        if !link_nodes(&mut nodes, input[edge_start + 2 * i] as usize, input[edge_start + 2 * i + 1] as usize) { return -1; }
    }
    let mut answers = [0i64; MAX_Q];
    let mut answer_count = 0usize;
    for i in 0..q {
        let at = operation_start + 5 * i;
        let kind = input[at] as usize;
        let a = input[at + 1] as usize;
        let b = input[at + 2] as usize;
        if kind == 0 {
            let c = input[at + 3] as usize;
            let d = input[at + 4] as usize;
            if !cut_nodes(&mut nodes, a, b) || !link_nodes(&mut nodes, c, d) { return -1; }
        } else if kind == 1 {
            access(&mut nodes, a);
            nodes[a].value += b as i64;
            pull(&mut nodes, a);
        } else {
            let Some(answer) = subtree_side_sum(&mut nodes, a, b) else { return -1; };
            answers[answer_count] = answer;
            answer_count += 1;
        }
    }
    let output_bytes = 8 * answer_count;
    if output_bytes > 0 && (output.is_null() || output_capacity < output_bytes) { return -2; }
    for i in 0..answer_count { put_i64_le(output, 8 * i, answers[i]); }
    output_bytes as i64
}
