use std::slice;

const MAX_N: usize = 64;
const MAX_Q: usize = 128;
const MAX_LEVEL: usize = 8;
const MAX_INPUT_VALUES: usize = 3 * MAX_N + 4 * MAX_Q + 1;
const MAX_ABS_VALUE: i64 = 1_000_000;

struct Context {
    n: usize,
    degree: [usize; MAX_N],
    adjacent: [[usize; MAX_N]; MAX_N],
    removed: [bool; MAX_N],
    parent: [i32; MAX_N],
    subtree_size: [usize; MAX_N],
    ancestor: [[i32; MAX_LEVEL]; MAX_N],
    distance: [[usize; MAX_LEVEL]; MAX_N],
    branch_for: [[i32; MAX_LEVEL]; MAX_N],
    path_length: [usize; MAX_N],
    branch_count: usize,
    total: [[i64; MAX_N + 1]; MAX_N],
    branch: [[i64; MAX_N + 1]; MAX_N],
}

impl Context {
    fn new(n: usize) -> Self {
        Self {
            n,
            degree: [0; MAX_N],
            adjacent: [[0; MAX_N]; MAX_N],
            removed: [false; MAX_N],
            parent: [-1; MAX_N],
            subtree_size: [0; MAX_N],
            ancestor: [[-1; MAX_LEVEL]; MAX_N],
            distance: [[0; MAX_LEVEL]; MAX_N],
            branch_for: [[-1; MAX_LEVEL]; MAX_N],
            path_length: [0; MAX_N],
            branch_count: 0,
            total: [[0; MAX_N + 1]; MAX_N],
            branch: [[0; MAX_N + 1]; MAX_N],
        }
    }
}

fn collect_component(ctx: &mut Context, start: usize, order: &mut [usize; MAX_N]) -> usize {
    let mut stack = [0usize; MAX_N];
    let (mut top, mut count) = (0usize, 0usize);
    ctx.parent[start] = -1;
    stack[top] = start;
    top += 1;
    while top > 0 {
        top -= 1;
        let u = stack[top];
        order[count] = u;
        count += 1;
        for i in 0..ctx.degree[u] {
            let v = ctx.adjacent[u][i];
            if ctx.removed[v] || ctx.parent[u] == v as i32 { continue; }
            ctx.parent[v] = u as i32;
            stack[top] = v;
            top += 1;
        }
    }
    for position in (0..count).rev() {
        let u = order[position];
        ctx.subtree_size[u] = 1;
        for i in 0..ctx.degree[u] {
            let v = ctx.adjacent[u][i];
            if !ctx.removed[v] && ctx.parent[v] == u as i32 {
                ctx.subtree_size[u] += ctx.subtree_size[v];
            }
        }
    }
    count
}

fn decompose(ctx: &mut Context, start: usize, level: usize) {
    let mut order = [0usize; MAX_N];
    let count = collect_component(ctx, start, &mut order);
    let mut center = start;
    for &u in order[..count].iter() {
        let mut largest = count - ctx.subtree_size[u];
        for i in 0..ctx.degree[u] {
            let v = ctx.adjacent[u][i];
            if !ctx.removed[v] && ctx.parent[v] == u as i32 {
                largest = largest.max(ctx.subtree_size[v]);
            }
        }
        if 2 * largest <= count { center = u; break; }
    }

    ctx.removed[center] = true;
    ctx.ancestor[center][level] = center as i32;
    ctx.distance[center][level] = 0;
    ctx.branch_for[center][level] = -1;
    ctx.path_length[center] = level + 1;

    for edge in 0..ctx.degree[center] {
        let root = ctx.adjacent[center][edge];
        if ctx.removed[root] { continue; }
        let branch_id = ctx.branch_count;
        ctx.branch_count += 1;
        let mut nodes = [0usize; MAX_N];
        let mut parents = [0usize; MAX_N];
        let mut distances = [0usize; MAX_N];
        let (mut top, mut seen_count) = (0usize, 0usize);
        nodes[top] = root; parents[top] = center; distances[top] = 1; top += 1;
        while top > 0 {
            top -= 1;
            let u = nodes[top];
            let p = parents[top];
            let d = distances[top];
            seen_count += 1;
            ctx.ancestor[u][level] = center as i32;
            ctx.distance[u][level] = d;
            ctx.branch_for[u][level] = branch_id as i32;
            ctx.path_length[u] = level + 1;
            for i in 0..ctx.degree[u] {
                let v = ctx.adjacent[u][i];
                if ctx.removed[v] || v == p { continue; }
                nodes[top] = v; parents[top] = u; distances[top] = d + 1; top += 1;
            }
        }
        let _ = seen_count;
        decompose(ctx, root, level + 1);
    }
}

fn fenwick_add(row: &mut [i64; MAX_N + 1], position: usize, delta: i64) {
    let mut index = position + 1;
    while index <= MAX_N {
        row[index] += delta;
        index += index & index.wrapping_neg();
    }
}

fn fenwick_prefix(row: &[i64; MAX_N + 1], count: usize) -> i64 {
    let mut sum = 0;
    let mut index = count;
    while index > 0 {
        sum += row[index];
        index -= index & index.wrapping_neg();
    }
    sum
}

fn row_range(row: &[i64; MAX_N + 1], left: i32, right: i32) -> i64 {
    let l = left.clamp(0, MAX_N as i32) as usize;
    let r = right.clamp(0, MAX_N as i32) as usize;
    if r <= l { 0 } else { fenwick_prefix(row, r) - fenwick_prefix(row, l) }
}

unsafe fn read_i64(input: *const i64, index: usize) -> i64 { *input.add(index) }

#[no_mangle]
pub unsafe extern "C" fn vertex_add_range_contour_sum_on_tree(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let (nv, qv) = (input[0], input[1]);
    if !(1..=MAX_N as i64).contains(&nv) || !(0..=MAX_Q as i64).contains(&qv) { return -1; }
    let (n, q) = (nv as usize, qv as usize);
    if length < 3 * n { return -1; }

    let mut ctx = Context::new(n);
    let mut values = [0i64; MAX_N];
    for v in 0..n {
        values[v] = input[2 + v];
        if !(-MAX_ABS_VALUE..=MAX_ABS_VALUE).contains(&values[v]) { return -1; }
    }
    let edge_start = 2 + n;
    for i in 0..n - 1 {
        let (u_value, v_value) = (input[edge_start + 2 * i], input[edge_start + 2 * i + 1]);
        if u_value < 0 || u_value >= nv || v_value < 0 || v_value >= nv || u_value == v_value { return -1; }
        let (u, v) = (u_value as usize, v_value as usize);
        if ctx.adjacent[u][..ctx.degree[u]].contains(&v) { return -1; }
        ctx.adjacent[u][ctx.degree[u]] = v; ctx.degree[u] += 1;
        ctx.adjacent[v][ctx.degree[v]] = u; ctx.degree[v] += 1;
    }
    let mut seen = [false; MAX_N];
    let mut stack = [0usize; MAX_N];
    let (mut top, mut visited) = (1usize, 0usize);
    stack[0] = 0; seen[0] = true;
    while top > 0 {
        top -= 1;
        let u = stack[top]; visited += 1;
        for i in 0..ctx.degree[u] {
            let v = ctx.adjacent[u][i];
            if !seen[v] { seen[v] = true; stack[top] = v; top += 1; }
        }
    }
    if visited != n { return -1; }

    let (mut kinds, mut vertices, mut first, mut second) =
        ([0i64; MAX_Q], [0usize; MAX_Q], [0i64; MAX_Q], [0i64; MAX_Q]);
    let mut cursor = 3 * n;
    let mut query_count = 0usize;
    for i in 0..q {
        if cursor >= length { return -1; }
        let op = input[cursor]; cursor += 1;
        if op == 0 {
            if cursor + 2 > length { return -1; }
            let (p, delta) = (input[cursor], input[cursor + 1]); cursor += 2;
            if p < 0 || p >= nv || !(-MAX_ABS_VALUE..=MAX_ABS_VALUE).contains(&delta) { return -1; }
            kinds[i] = 0; vertices[i] = p as usize; first[i] = delta;
        } else if op == 1 {
            if cursor + 3 > length { return -1; }
            let (p, left, right) = (input[cursor], input[cursor + 1], input[cursor + 2]); cursor += 3;
            if p < 0 || p >= nv || left < 0 || left >= right || right > nv { return -1; }
            kinds[i] = 1; vertices[i] = p as usize; first[i] = left; second[i] = right; query_count += 1;
        } else { return -1; }
    }
    if cursor != length { return -1; }

    decompose(&mut ctx, 0, 0);
    for v in 0..n {
        for d in 0..ctx.path_length[v] {
            let c = ctx.ancestor[v][d] as usize;
            let branch = ctx.branch_for[v][d];
            fenwick_add(&mut ctx.total[c], ctx.distance[v][d], values[v]);
            if branch >= 0 { fenwick_add(&mut ctx.branch[branch as usize], ctx.distance[v][d], values[v]); }
        }
    }

    let mut answers = [0i64; MAX_Q];
    let mut answer_count = 0usize;
    for i in 0..q {
        let p = vertices[i];
        if kinds[i] == 0 {
            for d in 0..ctx.path_length[p] {
                let c = ctx.ancestor[p][d] as usize;
                let branch = ctx.branch_for[p][d];
                fenwick_add(&mut ctx.total[c], ctx.distance[p][d], first[i]);
                if branch >= 0 { fenwick_add(&mut ctx.branch[branch as usize], ctx.distance[p][d], first[i]); }
            }
        } else {
            let (left, right) = (first[i] as i32, second[i] as i32);
            let mut total = 0;
            for d in 0..ctx.path_length[p] {
                let c = ctx.ancestor[p][d] as usize;
                let branch = ctx.branch_for[p][d];
                let l = left - ctx.distance[p][d] as i32;
                let r = right - ctx.distance[p][d] as i32;
                total += row_range(&ctx.total[c], l, r);
                if branch >= 0 { total -= row_range(&ctx.branch[branch as usize], l, r); }
            }
            answers[answer_count] = total; answer_count += 1;
        }
    }
    let output_bytes = 8 * answer_count;
    if output_bytes > 0 && (output_ptr.is_null() || capacity < output_bytes) { return -2; }
    if output_bytes > 0 {
        let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
        for i in 0..answer_count { output[8 * i..8 * i + 8].copy_from_slice(&answers[i].to_le_bytes()); }
    }
    output_bytes as i64
}
