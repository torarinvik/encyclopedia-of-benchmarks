const MAX_N: usize = 16;
const MAX_Q: usize = 32;
const MAX_EDGES: usize = 15;
const LOG_N: usize = 5;

fn root_of(parent: &mut [usize; MAX_N], mut node: usize) -> usize {
    while parent[node] != node {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    node
}

fn point_set(tree: &mut [i64; 64], base: usize, index: usize, value: i64) {
    let mut position = base + index;
    tree[position] = value;
    position /= 2;
    while position > 0 {
        tree[position] = tree[2 * position] + tree[2 * position + 1];
        position /= 2;
    }
}

fn range_sum(tree: &[i64; 64], base: usize, left: usize, right: usize) -> i64 {
    if left > right { return 0; }
    let (mut l, mut r) = (base + left, base + right + 1);
    let mut total = 0i64;
    while l < r {
        if l & 1 == 1 { total += tree[l]; l += 1; }
        if r & 1 == 1 { r -= 1; total += tree[r]; }
        l /= 2; r /= 2;
    }
    total
}

fn lca(mut a: usize, mut b: usize, depth: &[usize; MAX_N], parent: &[usize; MAX_N],
       ancestor: &[[usize; MAX_N]; LOG_N]) -> usize {
    if depth[a] < depth[b] { std::mem::swap(&mut a, &mut b); }
    let mut difference = depth[a] - depth[b];
    let mut bit = 0;
    while difference != 0 {
        if difference & 1 != 0 { a = ancestor[bit][a]; }
        difference >>= 1;
        bit += 1;
    }
    if a == b { return a; }
    for bit in (0..LOG_N).rev() {
        if ancestor[bit][a] != ancestor[bit][b] {
            a = ancestor[bit][a]; b = ancestor[bit][b];
        }
    }
    parent[a]
}

fn solve(input: &[i64]) -> i64 {
    if input.len() < 2 || input.len() > 129 { return -1; }
    let n = input[0];
    let q = input[1];
    if !(1..=MAX_N as i64).contains(&n) || !(0..=MAX_Q as i64).contains(&q) { return -1; }
    let (n, q) = (n as usize, q as usize);
    let m = n - 1;
    if input.len() != 2 + 2 * m + 3 * q { return -1; }

    let mut edge_u = [0usize; MAX_EDGES];
    let mut edge_v = [0usize; MAX_EDGES];
    let mut dsu = std::array::from_fn(|i| i);
    let mut cursor = 2;
    for edge in 0..m {
        let (u, v) = (input[cursor], input[cursor + 1]); cursor += 2;
        if u < 0 || u >= n as i64 || v < 0 || v >= n as i64 || u == v { return -1; }
        let (u, v) = (u as usize, v as usize);
        edge_u[edge] = u; edge_v[edge] = v;
        let ru = root_of(&mut dsu, u);
        let rv = root_of(&mut dsu, v);
        if ru == rv { return -1; }
        dsu[ru] = rv;
    }
    let root = root_of(&mut dsu, 0);
    for v in 1..n { if root_of(&mut dsu, v) != root { return -1; } }

    let mut parent = [0usize; MAX_N];
    let mut depth = [0usize; MAX_N];
    let mut first = [0usize; MAX_N];
    let mut down = [0usize; MAX_EDGES];
    let mut up = [0usize; MAX_EDGES];
    let mut visited = [false; MAX_N];
    let mut stack_node = [0usize; MAX_N];
    let mut stack_parent = [0usize; MAX_N];
    let mut stack_in = [0usize; MAX_N];
    let mut stack_cursor = [0usize; MAX_N];
    let mut top: isize = 0;
    let mut occurrences = 0usize;
    visited[0] = true;
    stack_parent[0] = MAX_N;
    stack_in[0] = MAX_EDGES;
    while top >= 0 {
        let slot = top as usize;
        let node = stack_node[slot];
        let mut found = false;
        while stack_cursor[slot] < m {
            let edge = stack_cursor[slot]; stack_cursor[slot] += 1;
            if edge_u[edge] != node && edge_v[edge] != node { continue; }
            let child = if edge_u[edge] == node { edge_v[edge] } else { edge_u[edge] };
            if child == stack_parent[slot] { continue; }
            if visited[child] { return -1; }
            visited[child] = true; parent[child] = node; depth[child] = depth[node] + 1;
            down[edge] = occurrences; occurrences += 1; first[child] = occurrences;
            top += 1; let child_slot = top as usize;
            stack_node[child_slot] = child; stack_parent[child_slot] = node;
            stack_in[child_slot] = edge; stack_cursor[child_slot] = 0;
            found = true; break;
        }
        if !found {
            let incoming = stack_in[slot]; top -= 1;
            if incoming != MAX_EDGES { up[incoming] = occurrences; occurrences += 1; }
        }
    }

    let mut ancestor = [[0usize; MAX_N]; LOG_N];
    for v in 0..n { ancestor[0][v] = parent[v]; }
    for k in 1..LOG_N {
        for v in 0..n { ancestor[k][v] = ancestor[k - 1][ancestor[k - 1][v]]; }
    }
    let mut base = 1usize; while base < occurrences { base *= 2; }
    let mut forward = [0i64; 64]; let mut backward = [0i64; 64];
    let mut painted = [false; MAX_EDGES];
    let mut total = 0i64;
    for _ in 0..q {
        let (kind, a, b) = (input[cursor], input[cursor + 1], input[cursor + 2]); cursor += 3;
        if kind == 0 {
            if a < 0 || a >= m as i64 || b != 0 { return -1; }
            let edge = a as usize;
            if !painted[edge] {
                painted[edge] = true;
                point_set(&mut forward, base, down[edge], 1);
                point_set(&mut backward, base, up[edge], 1);
            }
        } else if kind == 1 {
            if a < 0 || a >= n as i64 || b < 0 || b >= n as i64 { return -1; }
            let common = lca(a as usize, b as usize, &depth, &parent, &ancestor);
            let (left_a, right_a) = (first[common], first[a as usize] as isize - 1);
            let (left_b, right_b) = (first[common], first[b as usize] as isize - 1);
            if right_a >= left_a as isize { total += range_sum(&forward, base, left_a, right_a as usize) - range_sum(&backward, base, left_a, right_a as usize); }
            if right_b >= left_b as isize { total += range_sum(&forward, base, left_b, right_b as usize) - range_sum(&backward, base, left_b, right_b as usize); }
        } else { return -1; }
    }
    total
}

#[no_mangle]
pub unsafe extern "C" fn tree_edge_paint_path_count(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 129 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
