//! Dynamic tree MWIS using heavy-light max-plus matrix products.
use core::ffi::c_uchar;

const N: usize = 64;
const Q: usize = 64;
const MAX_INPUT: usize = 320;
const MAX_WEIGHT: i64 = 1_000_000;
const NEG: i64 = -(1_i64 << 60);
type Matrix = [[i64; 2]; 2];

fn identity() -> Matrix { [[0, NEG], [NEG, 0]] }

fn multiply(a: Matrix, b: Matrix) -> Matrix {
    let mut out = [[0; 2]; 2];
    for row in 0..2 {
        for col in 0..2 {
            out[row][col] = (a[row][0] + b[0][col]).max(a[row][1] + b[1][col]);
        }
    }
    out
}

fn find_root(parent: &mut [usize; N], mut v: usize) -> usize {
    while parent[v] != v { parent[v] = parent[parent[v]]; v = parent[v]; }
    v
}

fn set_matrix(tree: &mut [Matrix; 2 * N], position: usize, value: Matrix) {
    let mut node = N + position;
    tree[node] = value;
    node /= 2;
    while node > 0 { tree[node] = multiply(tree[2 * node], tree[2 * node + 1]); node /= 2; }
}

fn query(tree: &[Matrix; 2 * N], left: usize, right: usize) -> Matrix {
    let mut l = N + left;
    let mut r = N + right;
    let mut before = identity();
    let mut after = identity();
    while l < r {
        if l & 1 != 0 { before = multiply(before, tree[l]); l += 1; }
        if r & 1 != 0 { r -= 1; after = multiply(tree[r], after); }
        l /= 2; r /= 2;
    }
    multiply(before, after)
}

fn summary(tree: &[Matrix; 2 * N], position: &[usize; N], tail: &[usize; N], head: usize) -> [i64; 2] {
    let p = query(tree, position[head], position[tail[head]] + 1);
    [p[0][0].max(p[0][1]), p[1][0].max(p[1][1])]
}

unsafe fn store_le(output: *mut c_uchar, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

unsafe fn read(input: *const i64, index: usize) -> i64 { *input.add(index) }

#[no_mangle]
pub unsafe extern "C" fn dynamic_tree_maximum_weight_independent_set(
    input: *const i64, length: usize, output: *mut c_uchar, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let nn = read(input, 0); let qq = read(input, 1);
    if nn < 1 || nn > N as i64 || qq < 0 || qq > Q as i64 { return -1; }
    let n = nn as usize; let q = qq as usize;
    let edge_end = 2 + n + 2 * (n - 1);
    if length != edge_end + 2 * q { return -1; }

    let mut dsu = [0usize; N];
    let mut weights = [0i64; N];
    let mut adjacency = [false; N * N];
    for u in 0..n {
        dsu[u] = u;
        weights[u] = read(input, 2 + u);
        if !(0..=MAX_WEIGHT).contains(&weights[u]) { return -1; }
    }
    for edge in 0..n - 1 {
        let off = 2 + n + 2 * edge;
        let (uv, vv) = (read(input, off), read(input, off + 1));
        if uv < 0 || uv >= nn || vv < 0 || vv >= nn || uv == vv { return -1; }
        let (u, v) = (uv as usize, vv as usize);
        let ru = find_root(&mut dsu, u); let rv = find_root(&mut dsu, v);
        if ru == rv { return -1; }
        dsu[ru] = rv;
        adjacency[u * N + v] = true; adjacency[v * N + u] = true;
    }
    let root_set = find_root(&mut dsu, 0);
    for v in 1..n { if find_root(&mut dsu, v) != root_set { return -1; } }

    let mut update_vertex = [0usize; Q];
    let mut update_weight = [0i64; Q];
    for i in 0..q {
        let off = edge_end + 2 * i;
        let (vertex, weight) = (read(input, off), read(input, off + 1));
        if vertex < 0 || vertex >= nn || !(0..=MAX_WEIGHT).contains(&weight) { return -1; }
        update_vertex[i] = vertex as usize; update_weight[i] = weight;
    }
    let output_bytes = 8 * q;
    if output_bytes > 0 && (output.is_null() || capacity < output_bytes) { return -2; }

    let mut parent = [-2isize; N];
    let mut order = [0usize; N];
    parent[0] = -1; order[0] = 0;
    let mut order_count = 1;
    let mut cursor = 0;
    while cursor < order_count {
        let u = order[cursor]; cursor += 1;
        for v in 0..n {
            if adjacency[u * N + v] && parent[v] == -2 {
                parent[v] = u as isize;
                order[order_count] = v; order_count += 1;
            }
        }
    }
    let mut subtree = [1usize; N];
    let mut heavy = [-1isize; N];
    let mut skip = [0i64; N];
    let mut take = [0i64; N];
    for u in 0..n { take[u] = weights[u]; }
    for index in (1..n).rev() {
        let u = order[index]; let p = parent[u] as usize;
        subtree[p] += subtree[u];
        if heavy[p] < 0 || subtree[u] > subtree[heavy[p] as usize] { heavy[p] = u as isize; }
        skip[p] += skip[u].max(take[u]); take[p] += skip[u];
    }

    let mut head = [0usize; N]; let mut position = [0usize; N]; let mut tail = [0usize; N];
    let mut stack = [0usize; N]; let mut stack_len = 1; let mut clock = 0;
    stack[0] = 0;
    while stack_len > 0 {
        stack_len -= 1; let h = stack[stack_len]; let mut u = h as isize;
        while u >= 0 {
            let vertex = u as usize;
            head[vertex] = h; position[vertex] = clock; clock += 1; tail[h] = vertex;
            for v in 1..n {
                if parent[v] == vertex as isize && heavy[vertex] != v as isize {
                    stack[stack_len] = v; stack_len += 1;
                }
            }
            u = heavy[vertex];
        }
    }

    let mut matrices = [identity(); N];
    let mut segment = [identity(); 2 * N];
    for u in 0..n {
        let mut light0 = 0i64; let mut light1 = weights[u];
        for v in 1..n {
            if parent[v] == u as isize && heavy[u] != v as isize {
                light0 += skip[v].max(take[v]); light1 += skip[v];
            }
        }
        matrices[u] = [[light0, light0], [light1, NEG]];
        segment[N + position[u]] = matrices[u];
    }
    for i in (1..N).rev() { segment[i] = multiply(segment[2 * i], segment[2 * i + 1]); }

    let mut staged = [0i64; Q];
    for i in 0..q {
        let vertex = update_vertex[i]; let mut h = head[vertex];
        let mut old_state = summary(&segment, &position, &tail, h);
        let delta = update_weight[i] - weights[vertex]; weights[vertex] = update_weight[i];
        matrices[vertex][1][0] += delta;
        set_matrix(&mut segment, position[vertex], matrices[vertex]);
        let mut new_state = summary(&segment, &position, &tail, h);
        while parent[h] != -1 {
            let p = parent[h] as usize; let ph = head[p];
            let before = summary(&segment, &position, &tail, ph);
            let d0 = new_state[0].max(new_state[1]) - old_state[0].max(old_state[1]);
            let d1 = new_state[0] - old_state[0];
            matrices[p][0][0] += d0; matrices[p][0][1] += d0; matrices[p][1][0] += d1;
            set_matrix(&mut segment, position[p], matrices[p]);
            old_state = before; new_state = summary(&segment, &position, &tail, ph); h = ph;
        }
        let answer = summary(&segment, &position, &tail, 0);
        staged[i] = answer[0].max(answer[1]);
    }
    for i in 0..q { store_le(output, 8 * i, staged[i]); }
    output_bytes as i64
}
