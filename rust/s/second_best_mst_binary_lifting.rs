fn merge(a: [i64; 2], b: [i64; 2]) -> [i64; 2] {
    let mut result = [-1, -1];
    for value in [a[0], a[1], b[0], b[1]] {
        if value > result[0] {
            result[1] = result[0];
            result[0] = value;
        } else if value < result[0] && value > result[1] {
            result[1] = value;
        }
    }
    result
}

fn root(parent: &mut [usize; 8], mut vertex: usize) -> usize {
    while parent[vertex] != vertex {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    vertex
}

fn solve(input: &[i64]) -> i64 {
    if !(2..=63).contains(&input.len()) { return -1; }
    let (nv, mv) = (input[0], input[1]);
    if !(1..=8).contains(&nv) || mv < nv - 1 || mv > 20 || input.len() != (2 + 3 * mv) as usize {
        return -1;
    }
    let (n, m) = (nv as usize, mv as usize);
    let mut edges = Vec::with_capacity(m);
    let mut seen = [[false; 8]; 8];
    for row in input[2..].chunks_exact(3) {
        let (u, v, weight) = (row[0], row[1], row[2]);
        if u < 0 || u >= v || v >= nv || !(0..=1_000_000).contains(&weight) {
            return -1;
        }
        let (u, v) = (u as usize, v as usize);
        if seen[u][v] { return -1; }
        seen[u][v] = true;
        edges.push((u, v, weight));
    }
    let mut order: Vec<usize> = (0..m).collect();
    order.sort_by_key(|&edge| (edges[edge].2, edge));
    let mut parent = [0; 8];
    for (vertex, slot) in parent.iter_mut().enumerate() { *slot = vertex; }
    let mut selected = [false; 20];
    let mut tree: [Vec<(usize, i64)>; 8] = std::array::from_fn(|_| Vec::new());
    let (mut count, mut total) = (0, 0);
    for edge in order {
        let (u, v, weight) = edges[edge];
        let (a, b) = (root(&mut parent, u), root(&mut parent, v));
        if a != b {
            parent[a] = b;
            selected[edge] = true;
            count += 1;
            total += weight;
            tree[u].push((v, weight));
            tree[v].push((u, weight));
        }
    }
    if count != n - 1 { return -1; }
    let mut up = [[0usize; 8]; 4];
    let mut best = [[[-1i64; 2]; 8]; 4];
    let mut depth = [-1i32; 8];
    depth[0] = 0;
    let mut queue = vec![0];
    let mut head = 0;
    while head < queue.len() {
        let vertex = queue[head];
        head += 1;
        for &(next, weight) in &tree[vertex] {
            if depth[next] >= 0 { continue; }
            depth[next] = depth[vertex] + 1;
            up[0][next] = vertex;
            best[0][next] = [weight, -1];
            queue.push(next);
        }
    }
    for level in 1..4 {
        for vertex in 0..n {
            let mid = up[level - 1][vertex];
            up[level][vertex] = up[level - 1][mid];
            best[level][vertex] = merge(best[level - 1][vertex], best[level - 1][mid]);
        }
    }
    let mut increase: Option<i64> = None;
    for (edge, &(mut a, mut b, weight)) in edges.iter().enumerate() {
        if selected[edge] { continue; }
        if depth[a] < depth[b] { std::mem::swap(&mut a, &mut b); }
        let mut path = [-1, -1];
        let difference = (depth[a] - depth[b]) as usize;
        for level in 0..4 {
            if difference & (1 << level) != 0 {
                path = merge(path, best[level][a]);
                a = up[level][a];
            }
        }
        if a != b {
            for level in (0..4).rev() {
                if up[level][a] != up[level][b] {
                    path = merge(merge(path, best[level][a]), best[level][b]);
                    a = up[level][a];
                    b = up[level][b];
                }
            }
            path = merge(merge(path, best[0][a]), best[0][b]);
        }
        let removed = if weight > path[0] { path[0] } else { path[1] };
        if removed >= 0 && removed < weight {
            let delta = weight - removed;
            increase = Some(increase.map_or(delta, |old| old.min(delta)));
        }
    }
    increase.map_or(0, |delta| total + delta + 1)
}

#[no_mangle]
pub unsafe extern "C" fn second_best_mst_binary_lifting(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=63).contains(&length) { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
