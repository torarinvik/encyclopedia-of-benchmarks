const MAX_NODES: usize = 256;
const MAX_QUERIES: usize = 1024;
const MAX_ARCS: usize = 2 * (MAX_NODES - 1);
const MAX_INPUT: usize = 4 + 2 * (MAX_NODES - 1) + 2 * MAX_QUERIES;

fn lowbit(value: u32) -> u32 { value & value.wrapping_neg() }

fn highbit(mut value: u32) -> u32 {
    let mut result = 0;
    while value != 0 { result = value; value >>= 1; }
    result
}

#[no_mangle]
pub unsafe extern "C" fn schieber_vishkin_lca(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT + 1 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_NODES as i64).contains(&input[0]) { return -1; }
    let n = input[0] as usize;
    if input[1] < 0 || input[1] >= n as i64 || input[2] != (n - 1) as i64 ||
        input[3] < 0 || input[3] > MAX_QUERIES as i64 { return -1; }
    let m = input[2] as usize;
    let q = input[3] as usize;
    let query_offset = 4 + 2 * m;
    if length != query_offset + 2 * q { return -1; }
    let root = input[1] as usize;

    let mut head = [-1i32; MAX_NODES];
    let mut arc_to = [0usize; MAX_ARCS];
    let mut arc_next = [-1i32; MAX_ARCS];
    let mut parent = [-2i32; MAX_NODES];
    let mut order = [0usize; MAX_NODES];
    let mut stack_node = [0usize; MAX_NODES];
    let mut stack_arc = [-1i32; MAX_NODES];
    let mut preorder = [0usize; MAX_NODES];
    let mut inlabel = [0u32; MAX_NODES];
    let mut ascendant = [0u32; MAX_NODES];
    let mut path_head = [0usize; MAX_NODES];
    let mut answers = [0u8; MAX_QUERIES];

    let mut arcs = 0usize;
    for edge in 0..m {
        let a = input[4 + 2 * edge];
        let b = input[5 + 2 * edge];
        if a < 0 || a >= n as i64 || b < 0 || b >= n as i64 || a == b { return -1; }
        let (a, b) = (a as usize, b as usize);
        arc_to[arcs] = b; arc_next[arcs] = head[a]; head[a] = arcs as i32; arcs += 1;
        arc_to[arcs] = a; arc_next[arcs] = head[b]; head[b] = arcs as i32; arcs += 1;
    }
    for query in 0..q {
        for side in 0..2 {
            let node = input[query_offset + 2 * query + side];
            if node < 0 || node >= n as i64 { return -1; }
        }
    }

    let mut reached = 1usize;
    let mut top = 1usize;
    parent[root] = -1;
    preorder[root] = 1;
    order[0] = root;
    stack_node[0] = root;
    stack_arc[0] = head[root];
    while top > 0 {
        let slot = top - 1;
        let node = stack_node[slot];
        let arc = stack_arc[slot];
        if arc < 0 { top -= 1; continue; }
        stack_arc[slot] = arc_next[arc as usize];
        let neighbor = arc_to[arc as usize];
        if neighbor as i32 == parent[node] { continue; }
        if parent[neighbor] != -2 { return -1; }
        parent[neighbor] = node as i32;
        preorder[neighbor] = reached + 1;
        order[reached] = neighbor;
        reached += 1;
        stack_node[top] = neighbor;
        stack_arc[top] = head[neighbor];
        top += 1;
    }
    if reached != n { return -1; }
    if output_capacity < q || (q != 0 && output.is_null()) { return -2; }

    for node in 0..n { inlabel[node] = preorder[node] as u32; }
    for i in (1..n).rev() {
        let node = order[i];
        let p = parent[node] as usize;
        if lowbit(inlabel[p]) < lowbit(inlabel[node]) { inlabel[p] = inlabel[node]; }
    }
    for i in 0..n {
        let node = order[i];
        if parent[node] < 0 {
            ascendant[node] = lowbit(inlabel[node]);
            path_head[preorder[node] - 1] = node;
        } else {
            let p = parent[node] as usize;
            ascendant[node] = ascendant[p] | lowbit(inlabel[node]);
            path_head[preorder[node] - 1] = if inlabel[node] != inlabel[p] {
                p
            } else {
                path_head[preorder[p] - 1]
            };
        }
    }

    for query in 0..q {
        let u = input[query_offset + 2 * query] as usize;
        let v = input[query_offset + 2 * query + 1] as usize;
        let lu = lowbit(inlabel[u]);
        let lv = lowbit(inlabel[v]);
        let mut mask = highbit((inlabel[u] ^ inlabel[v]) | lu | lv) - 1;
        let j = lowbit(ascendant[u] & ascendant[v] & !mask);
        if j == 0 { return -1; }
        let mut x = u;
        let mut y = v;
        if j != lu {
            mask = highbit(ascendant[u] & (j - 1)) - 1;
            let index = ((preorder[u] & !(mask as usize)) | (mask as usize + 1)) - 1;
            x = path_head[index];
        }
        if j != lv {
            mask = highbit(ascendant[v] & (j - 1)) - 1;
            let index = ((preorder[v] & !(mask as usize)) | (mask as usize + 1)) - 1;
            y = path_head[index];
        }
        answers[query] = if preorder[x] < preorder[y] { x as u8 } else { y as u8 };
    }
    for query in 0..q { *output.add(query) = answers[query]; }
    q as i64
}
