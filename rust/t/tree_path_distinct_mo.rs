const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_INPUT: usize = 3 * MAX_N + 2 * MAX_Q;

#[derive(Clone, Copy, Default)]
struct Query {
    left: usize,
    right: usize,
    id: usize,
    block: usize,
    right_key: usize,
}

fn find_root(parent: &mut [usize; MAX_N], mut item: usize) -> usize {
    while parent[item] != item {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    item
}

fn make_euler(
    vertex: usize,
    previous: usize,
    n: usize,
    adjacent: &[[bool; MAX_N]; MAX_N],
    parent: &mut [usize; MAX_N],
    depth: &mut [usize; MAX_N],
    entry: &mut [usize; MAX_N],
    leave: &mut [usize; MAX_N],
    euler: &mut [usize; 2 * MAX_N],
    clock: &mut usize,
) {
    parent[vertex] = previous;
    entry[vertex] = *clock;
    euler[*clock] = vertex;
    *clock += 1;
    for next in 0..n {
        if adjacent[vertex][next] && next != previous {
            depth[next] = depth[vertex] + 1;
            make_euler(next, vertex, n, adjacent, parent, depth, entry, leave, euler, clock);
        }
    }
    leave[vertex] = *clock;
    euler[*clock] = vertex;
    *clock += 1;
}

fn lca(
    mut a: usize,
    mut b: usize,
    parent: &[usize; MAX_N],
    depth: &[usize; MAX_N],
) -> usize {
    while depth[a] > depth[b] { a = parent[a]; }
    while depth[b] > depth[a] { b = parent[b]; }
    while a != b { a = parent[a]; b = parent[b]; }
    a
}

fn toggle(
    vertex: usize,
    color_id: &[usize; MAX_N],
    counts: &mut [usize; MAX_N],
    active: &mut [bool; MAX_N],
    distinct: &mut usize,
) {
    let color = color_id[vertex];
    if active[vertex] {
        active[vertex] = false;
        counts[color] -= 1;
        if counts[color] == 0 { *distinct -= 1; }
    } else {
        active[vertex] = true;
        if counts[color] == 0 { *distinct += 1; }
        counts[color] += 1;
    }
}

fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { output.add(offset + byte).write((bits >> (8 * byte)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tree_path_distinct_mo(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT + 1 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let n_value = words[0];
    let q_value = words[1];
    if n_value < 1 || n_value > MAX_N as i64 || q_value < 0 || q_value > MAX_Q as i64 {
        return -1;
    }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 3 * n + 2 * q { return -1; }

    let mut colors = [0i64; MAX_N];
    colors[..n].copy_from_slice(&words[2..2 + n]);
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut dsu_parent = [0usize; MAX_N];
    let mut dsu_size = [0usize; MAX_N];
    for vertex in 0..n { dsu_parent[vertex] = vertex; dsu_size[vertex] = 1; }
    let mut offset = 2 + n;
    for _ in 0..n - 1 {
        let (u_value, v_value) = (words[offset], words[offset + 1]);
        offset += 2;
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
            || u_value == v_value { return -1; }
        let (u, v) = (u_value as usize, v_value as usize);
        let (mut root_u, mut root_v) = (find_root(&mut dsu_parent, u), find_root(&mut dsu_parent, v));
        if root_u == root_v { return -1; }
        if dsu_size[root_u] < dsu_size[root_v] { std::mem::swap(&mut root_u, &mut root_v); }
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }

    let mut query_u = [0usize; MAX_Q];
    let mut query_v = [0usize; MAX_Q];
    for id in 0..q {
        let (u, v) = (words[offset], words[offset + 1]);
        offset += 2;
        if u < 0 || u >= n_value || v < 0 || v >= n_value { return -1; }
        query_u[id] = u as usize;
        query_v[id] = v as usize;
    }

    let mut color_id = [0usize; MAX_N];
    let mut first_color = [0usize; MAX_N];
    let mut color_count = 0;
    for vertex in 0..n {
        let mut rank = 0;
        while rank < color_count && colors[first_color[rank]] != colors[vertex] { rank += 1; }
        if rank == color_count { first_color[color_count] = vertex; color_count += 1; }
        color_id[vertex] = rank;
    }

    let mut parent = [n; MAX_N];
    let mut depth = [0usize; MAX_N];
    let mut entry = [0usize; MAX_N];
    let mut leave = [0usize; MAX_N];
    let mut euler = [0usize; 2 * MAX_N];
    let mut clock = 0;
    make_euler(0, n, n, &adjacent, &mut parent, &mut depth,
        &mut entry, &mut leave, &mut euler, &mut clock);

    let mut queries = [Query::default(); MAX_Q];
    let mut block_size = 1;
    while (block_size + 1) * (block_size + 1) <= 2 * n { block_size += 1; }
    for id in 0..q {
        let (mut u, mut v) = (query_u[id], query_v[id]);
        if entry[u] > entry[v] { std::mem::swap(&mut u, &mut v); }
        let ancestor = lca(u, v, &parent, &depth);
        let left = if ancestor == u { entry[u] } else { leave[u] };
        let right = entry[v];
        let block = left / block_size;
        queries[id] = Query { left, right, id, block,
            right_key: if block % 2 == 0 { right } else { 2 * n - 1 - right } };
    }
    queries[..q].sort_by_key(|query| (query.block, query.right_key, query.id));

    let mut counts = [0usize; MAX_N];
    let mut active = [false; MAX_N];
    let mut answers = [0usize; MAX_Q];
    let mut distinct = 0usize;
    let (mut left, mut right) = (0isize, -1isize);
    for query in &queries[..q] {
        while left > query.left as isize {
            left -= 1;
            toggle(euler[left as usize], &color_id, &mut counts, &mut active, &mut distinct);
        }
        while right < query.right as isize {
            right += 1;
            toggle(euler[right as usize], &color_id, &mut counts, &mut active, &mut distinct);
        }
        while left < query.left as isize {
            toggle(euler[left as usize], &color_id, &mut counts, &mut active, &mut distinct);
            left += 1;
        }
        while right > query.right as isize {
            toggle(euler[right as usize], &color_id, &mut counts, &mut active, &mut distinct);
            right -= 1;
        }
        let ancestor = lca(query_u[query.id], query_v[query.id], &parent, &depth);
        if ancestor != query_u[query.id] && ancestor != query_v[query.id] {
            toggle(ancestor, &color_id, &mut counts, &mut active, &mut distinct);
            answers[query.id] = distinct;
            toggle(ancestor, &color_id, &mut counts, &mut active, &mut distinct);
        } else {
            answers[query.id] = distinct;
        }
    }

    let required = 8 * q;
    if output.is_null() || capacity < required { return -2; }
    for id in 0..q { store_le(output, 8 * id, answers[id] as i64); }
    required as i64
}
