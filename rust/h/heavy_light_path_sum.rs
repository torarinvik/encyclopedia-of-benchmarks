const MAX_N: usize = 64;
const MAX_Q: usize = 128;

fn range_max(tree: &[i64; MAX_N * 2], n: usize, left: usize, right: usize) -> i64 {
    let mut l = left + n;
    let mut r = right + n + 1;
    let mut maximum = i32::MIN as i64;
    while l < r {
        if l & 1 != 0 { maximum = maximum.max(tree[l]); l += 1; }
        if r & 1 != 0 { r -= 1; maximum = maximum.max(tree[r]); }
        l >>= 1;
        r >>= 1;
    }
    maximum
}

fn point_set(tree: &mut [i64; MAX_N * 2], n: usize, position: usize, value: i64) {
    let mut p = position + n;
    tree[p] = value;
    while p > 1 {
        p >>= 1;
        tree[p] = tree[p * 2].max(tree[p * 2 + 1]);
    }
}

fn path_max(tree: &[i64; MAX_N * 2], n: usize, parent: &[usize; MAX_N],
    depth: &[usize; MAX_N], head: &[usize; MAX_N], position: &[usize; MAX_N],
    a_value: usize, b_value: usize) -> i64 {
    let (mut a, mut b) = (a_value, b_value);
    let mut maximum = i32::MIN as i64;
    while head[a] != head[b] {
        if depth[head[a]] < depth[head[b]] { std::mem::swap(&mut a, &mut b); }
        maximum = maximum.max(range_max(tree, n, position[head[a]], position[a]));
        a = parent[head[a]];
    }
    if depth[a] > depth[b] { std::mem::swap(&mut a, &mut b); }
    maximum.max(range_max(tree, n, position[a], position[b]))
}

unsafe fn put_i64(output: *mut u8, slot: usize, value: i64) {
    for (byte, value_byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(slot * 8 + byte) = *value_byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn heavy_light_path_max(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let q_value = values[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 3 * n + 3 * q { return -1; }

    let mut node_values = [0i64; MAX_N];
    let mut cursor = 2;
    for v in 0..n {
        let value = values[cursor];
        cursor += 1;
        if !(-2_147_483_648..=2_147_483_647).contains(&value) { return -1; }
        node_values[v] = value;
    }
    let mut adjacency = [[0usize; MAX_N]; MAX_N];
    let mut degree = [0usize; MAX_N];
    for _ in 0..n - 1 {
        let (uv, vv) = (values[cursor], values[cursor + 1]);
        cursor += 2;
        if uv < 0 || uv as usize >= n || vv < 0 || vv as usize >= n || uv == vv { return -1; }
        let (u, v) = (uv as usize, vv as usize);
        if adjacency[u][..degree[u]].contains(&v) { return -1; }
        adjacency[u][degree[u]] = v; degree[u] += 1;
        adjacency[v][degree[v]] = u; degree[v] += 1;
    }

    let mut parent = [usize::MAX; MAX_N];
    let mut depth = [0usize; MAX_N];
    let mut order = [0usize; MAX_N];
    let mut stack = [0usize; MAX_N];
    parent[0] = 0;
    let (mut top, mut order_count) = (1usize, 0usize);
    stack[0] = 0;
    while top > 0 {
        top -= 1;
        let u = stack[top];
        order[order_count] = u;
        order_count += 1;
        for i in 0..degree[u] {
            let v = adjacency[u][i];
            if v == parent[u] { continue; }
            if parent[v] != usize::MAX { return -1; }
            parent[v] = u;
            depth[v] = depth[u] + 1;
            stack[top] = v; top += 1;
        }
    }
    if order_count != n { return -1; }

    let mut subtree = [1usize; MAX_N];
    let mut heavy = [usize::MAX; MAX_N];
    for idx in (1..n).rev() {
        let v = order[idx];
        let p = parent[v];
        subtree[p] += subtree[v];
        if heavy[p] == usize::MAX || subtree[v] > subtree[heavy[p]] { heavy[p] = v; }
    }
    let mut head = [0usize; MAX_N];
    let mut position = [0usize; MAX_N];
    let mut todo_vertex = [0usize; MAX_N];
    let mut todo_head = [0usize; MAX_N];
    let mut base = [0i64; MAX_N];
    let (mut todo, mut timer) = (1usize, 0usize);
    todo_vertex[0] = 0; todo_head[0] = 0;
    while todo > 0 {
        todo -= 1;
        let (mut u, chain) = (todo_vertex[todo], todo_head[todo]);
        while u != usize::MAX {
            head[u] = chain;
            position[u] = timer;
            base[timer] = node_values[u];
            timer += 1;
            for i in 0..degree[u] {
                let v = adjacency[u][i];
                if parent[v] == u && v != heavy[u] {
                    todo_vertex[todo] = v; todo_head[todo] = v; todo += 1;
                }
            }
            u = heavy[u];
        }
    }
    let mut segment = [0i64; MAX_N * 2];
    for i in 0..n { segment[n + i] = base[i]; }
    for i in (1..n).rev() { segment[i] = segment[i * 2].max(segment[i * 2 + 1]); }

    let mut results = [0i64; MAX_Q];
    let mut result_count = 0usize;
    let operations = cursor;
    for i in 0..q {
        let op = values[operations + 3 * i];
        let av = values[operations + 3 * i + 1];
        let bv = values[operations + 3 * i + 2];
        if op == 0 {
            if av < 0 || av as usize >= n || !(-2_147_483_648..=2_147_483_647).contains(&bv) { return -1; }
            node_values[av as usize] = bv;
            point_set(&mut segment, n, position[av as usize], bv);
        } else if op == 1 {
            if av < 0 || av as usize >= n || bv < 0 || bv as usize >= n { return -1; }
            results[result_count] = path_max(&segment, n, &parent, &depth, &head, &position, av as usize, bv as usize);
            result_count += 1;
        } else { return -1; }
    }
    let output_bytes = result_count * 8;
    if output_bytes > 0 && (output.is_null() || capacity < output_bytes) { return -2; }
    for i in 0..result_count { unsafe { put_i64(output, i, results[i]); } }
    output_bytes as i64
}
